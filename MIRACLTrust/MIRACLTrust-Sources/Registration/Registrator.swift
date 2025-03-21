import Foundation

let INVALID_ACTIVATION_TOKEN = "INVALID_ACTIVATION_TOKEN"

final class Registrator: Sendable {
    let userId: String
    let activationToken: String
    let deviceName: String
    let pushNotificationsToken: String?
    let didRequestPinHandler: PinRequestHandler
    let completionHandler: RegistrationCompletionHandler
    let miraclAPI: APIBlueprint
    let crypto: CryptoBlueprint
    let projectId: String
    let userStorage: UserStorage
    let miraclLogger: MIRACLLogger

    private let pinLengthRange = 4 ... 6

    init(
        userId: String,
        activationToken: String,
        deviceName: String = MIRACLTrust.getInstance().deviceName,
        pushNotificationsToken: String? = nil,
        api: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        userStorage: UserStorage = MIRACLTrust.getInstance().userStorage,
        projectId: String = MIRACLTrust.getInstance().projectId,
        crypto: CryptoBlueprint = MIRACLTrust.getInstance().crypto,
        miraclLogger: MIRACLLogger = MIRACLTrust.getInstance().miraclLogger,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping RegistrationCompletionHandler
    ) throws {
        self.userId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.activationToken = activationToken
        self.deviceName = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.pushNotificationsToken = pushNotificationsToken
        self.didRequestPinHandler = didRequestPinHandler

        self.completionHandler = completionHandler
        miraclAPI = api
        self.crypto = crypto

        self.projectId = projectId
        self.userStorage = userStorage
        self.miraclLogger = miraclLogger

        try validateInput()
    }

    init(
        userId: String,
        api: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        userStorage: UserStorage = MIRACLTrust.getInstance().userStorage,
        projectId: String = MIRACLTrust.getInstance().projectId,
        crypto: CryptoBlueprint = MIRACLTrust.getInstance().crypto,
        miraclLogger: MIRACLLogger = MIRACLTrust.getInstance().miraclLogger,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping RegistrationCompletionHandler
    ) {
        self.userId = userId
        activationToken = ""
        deviceName = ""
        pushNotificationsToken = ""
        self.projectId = projectId
        self.userStorage = userStorage

        self.didRequestPinHandler = didRequestPinHandler
        self.completionHandler = completionHandler
        miraclAPI = api
        self.crypto = crypto
        self.miraclLogger = miraclLogger
    }

    func register() {
        miraclLogger.info(
            message: LoggingConstants.started,
            category: .registration
        )

        DispatchQueue.global(qos: .default).async {
            self.registerUser()
        }
    }

    // MARK: Private

    private func registerUser() {
        logOperation(operation: LoggingConstants.registerRequest)

        miraclAPI.registerUser(
            for: userId,
            deviceName: deviceName,
            activationToken: activationToken,
            pushToken: pushNotificationsToken,
            completionHandler: { apiCallResult, registerResponse, error in
                if apiCallResult == .failed, let error = error {
                    if case let APIError.apiClientError(clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = error, let clientErrorData, clientErrorData.code == INVALID_ACTIVATION_TOKEN {
                        self.callCompletionHandlerWithError(error: RegistrationError.invalidActivationToken)
                        return
                    }

                    self.logOperation(operation: "registerUser error = \(error)")

                    self.callCompletionHandlerWithError(
                        error: RegistrationError.registrationFail(error)
                    )
                    return
                }

                guard let registerResponse = registerResponse else {
                    self.logOperation(operation: "registerUser error with nil response")

                    self.callCompletionHandlerWithError(
                        error: RegistrationError.registrationFail(error)
                    )
                    return
                }

                if registerResponse.projectId != self.projectId {
                    self.callCompletionHandlerWithError(error: RegistrationError.projectMismatch)
                    return
                }

                let trimmedMpinId = registerResponse.mpinId.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedRegOtt = registerResponse.regOTT.trimmingCharacters(in: .whitespacesAndNewlines)

                if trimmedMpinId.isEmpty || trimmedRegOtt.isEmpty {
                    self.callCompletionHandlerWithError(error: RegistrationError.registrationFail(nil))
                    return
                }

                self.signature(
                    mpinIdString: trimmedMpinId,
                    regOTT: trimmedRegOtt
                )
            }
        )
    }

    private func signature(mpinIdString: String, regOTT: String) {
        logOperation(operation: LoggingConstants.signatureRequest)

        let keyPairResult = crypto.generateKeyPair()

        if let cryptoError = keyPairResult.error {
            callCompletionHandlerWithError(
                error: RegistrationError.registrationFail(cryptoError)
            )
            return
        }

        miraclAPI.signature(for: mpinIdString, regOTT: regOTT, publicKey: keyPairResult.publicKey.hex) { apiCallResult, signatureResponse, error in

            if apiCallResult == .failed, let error = error {
                self.logOperation(operation: "signature error = \(error)")

                self.callCompletionHandlerWithError(error: RegistrationError.registrationFail(error))
                return
            }

            guard let signatureResponse = signatureResponse else {
                self.logOperation(operation: "signature response = nil")

                self.callCompletionHandlerWithError(error: RegistrationError.registrationFail(nil)
                )
                return
            }

            let trimmedCS1 = signatureResponse.dvsClientSecretShare.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCurve = signatureResponse.curve.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDtas = signatureResponse.dtas.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedCS1.isEmpty || trimmedCurve.isEmpty || trimmedDtas.isEmpty {
                self.callCompletionHandlerWithError(
                    error: RegistrationError.registrationFail(nil)
                )
                return
            }

            // Returned curve is not supported by this version of the SDK, so throw error.
            if CryptoSupportedEllipticCurves(rawValue: trimmedCurve) == nil {
                self.callCompletionHandlerWithError(error: RegistrationError.unsupportedEllipticCurve)
                return
            }

            guard let cs2URL = signatureResponse.cs2URL else {
                self.logOperation(operation: "No cs2URL.")
                self.callCompletionHandlerWithError(
                    error: RegistrationError.registrationFail(nil)
                )
                return
            }

            self.getClientSecret2(
                cs2URL: cs2URL,
                mpinId: mpinIdString,
                clientSecret1: Data(hexString: trimmedCS1),
                dtas: trimmedDtas,
                keypair: (keyPairResult.privateKey, keyPairResult.publicKey)
            )
        }
    }

    func getWAMSecret(dvsRegistrationToken: String) {
        logOperation(operation: LoggingConstants.getSigningClientSecret1)

        let (privateKey, publicKey, cryptoError) = crypto.generateKeyPair()
        let keypair = (privateKey, publicKey)

        if let cryptoError {
            callCompletionHandlerWithError(error: RegistrationError.registrationFail(cryptoError))
            return
        }

        miraclAPI.signingClientSecret1(
            publicKey: publicKey.hex,
            signingRegistrationToken: dvsRegistrationToken,
            deviceName: deviceName
        ) { _, response, error in
            if let error {
                self.callCompletionHandlerWithError(error: RegistrationError.registrationFail(error))
                return
            }

            guard let response else {
                self.callCompletionHandlerWithError(error: RegistrationError.registrationFail(nil))
                return
            }

            let trimmedMpinId = response
                .mpinId
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDtas = response
                .dtas
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCSS = response
                .signingClientSecretShare
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedMpinId.isEmpty || trimmedDtas.isEmpty || trimmedCSS.isEmpty {
                self.callCompletionHandlerWithError(
                    error: RegistrationError.registrationFail(nil)
                )
                return
            }

            guard let cs2URL = response.cs2URL else {
                self.callCompletionHandlerWithError(
                    error: RegistrationError.registrationFail(nil)
                )
                return
            }

            self.getClientSecret2(
                cs2URL: cs2URL,
                mpinId: trimmedMpinId,
                clientSecret1: Data(hexString: trimmedCSS),
                dtas: trimmedDtas,
                keypair: keypair
            )
        }
    }

    private func getClientSecret2(
        cs2URL: URL,
        mpinId: String,
        clientSecret1: Data,
        dtas: String,
        keypair: (privateKey: Data, publicKey: Data)
    ) {
        logOperation(operation: LoggingConstants.cs2Request)

        miraclAPI.getClientSecret2(for: cs2URL) { apiCallResult, clientSecretResponse, error in

            if apiCallResult == .failed, let error = error {
                self.logOperation(operation: "getClientSecret2 error = \(error)")
                self.callCompletionHandlerWithError(error: RegistrationError.registrationFail(error))
                return
            }

            guard let clientSecretResponse = clientSecretResponse else {
                self.logOperation(operation: "getClientSecret2 = nil")
                self.callCompletionHandlerWithError(
                    error: RegistrationError.registrationFail(nil)
                )
                return
            }

            let trimmedCS2 = clientSecretResponse.dvsClientSecret.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedCS2.isEmpty {
                self.callCompletionHandlerWithError(
                    error: RegistrationError.registrationFail(nil)
                )
                return
            }

            self.getClientToken(
                mpinId: mpinId,
                clientSecret1: clientSecret1,
                clientSecret2: Data(hexString: trimmedCS2),
                dtas: dtas,
                keypair: keypair
            )
        }
    }

    private func getClientToken(
        mpinId: String,
        clientSecret1: Data,
        clientSecret2: Data,
        dtas: String,
        keypair: (privateKey: Data, publicKey: Data)
    ) {
        logOperation(operation: LoggingConstants.getClientToken)

        let result = getPinCode()
        var pin = Int32()
        var pinLength = Int()

        switch result {
        case let .success(pinTuple):
            pin = pinTuple.enteredPin
            pinLength = pinTuple.enteredPinLength
        case let .failure(error):
            callCompletionHandlerWithError(error: error)
            return
        }
        let publicKey = keypair.publicKey
        var combinedMpinId = Data(hexString: mpinId)
        combinedMpinId.append(publicKey)

        let (clientTokenData, tokenCryptoError) =
            crypto.getSigningClientToken(
                clientSecret1: clientSecret1,
                clientSecret2: clientSecret2,
                privateKey: keypair.privateKey,
                signingMpinId: combinedMpinId,
                pinCode: pin
            )

        if let tokenCryptoError = tokenCryptoError {
            callCompletionHandlerWithError(error: RegistrationError.registrationFail(tokenCryptoError))
            return
        }

        if clientTokenData.isEmpty {
            callCompletionHandlerWithError(error: RegistrationError.registrationFail(nil))
            return
        }

        addOrUpdateUser(
            pinLength: pinLength,
            mpinId: mpinId,
            clientTokenData: clientTokenData,
            dtas: dtas,
            publicKey: publicKey
        )
    }

    private func addOrUpdateUser(
        pinLength: Int,
        mpinId: String,
        clientTokenData: Data,
        dtas: String,
        publicKey: Data
    ) {
        do {
            let user = User(
                userId: userId,
                projectId: projectId,
                revoked: false,
                pinLength: pinLength,
                mpinId: Data(hexString: mpinId),
                token: clientTokenData,
                dtas: dtas,
                publicKey: publicKey
            )

            if userStorage.getUser(
                by: userId,
                projectId: projectId
            ) != nil {
                miraclLogger.info(
                    message: LoggingConstants.registrationOverride,
                    category: .registration
                )

                try userStorage.update(user: user)

                DispatchQueue.main.async {
                    self.completionHandler(user, nil)
                }
            } else {
                miraclLogger.info(
                    message: LoggingConstants.storageАddAuthenticationIdentity,
                    category: .registration
                )

                try userStorage.add(user: user)

                DispatchQueue.main.async {
                    self.completionHandler(user, nil)
                }
            }

            miraclLogger.info(
                message: LoggingConstants.finished,
                category: .registration
            )
        } catch {
            callCompletionHandlerWithError(error: error)
        }
    }

    private func callCompletionHandlerWithError(error: Error) {
        logOperation(operation: "\(LoggingConstants.finishedWithError)=\(error)")

        DispatchQueue.main.async {
            self.completionHandler(nil, error)
        }
    }

    private func validateInput() throws {
        if userId.isEmpty {
            throw RegistrationError.emptyUserId
        }

        if activationToken.isEmpty {
            throw RegistrationError.emptyActivationToken
        }
    }

    private func logOperation(operation: String) {
        miraclLogger.info(
            message: "\(operation)",
            category: .registration
        )
    }

    private func getPinCode() -> Result<(enteredPin: Int32, enteredPinLength: Int), RegistrationError> {
        nonisolated(unsafe) var userEnteredPin: String?
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            self.didRequestPinHandler { pin in
                userEnteredPin = pin
                semaphore.signal()
            }
        }

        _ = semaphore.wait(timeout: .distantFuture)

        guard let pinCode = userEnteredPin else {
            return .failure(.pinCancelled)
        }

        guard let pin = Int32(pinCode) else {
            return .failure(.invalidPin)
        }

        if !pinLengthRange.contains(pinCode.count) {
            return .failure(.invalidPin)
        }

        return .success(
            (enteredPin: pin, enteredPinLength: pinCode.count)
        )
    }
}
