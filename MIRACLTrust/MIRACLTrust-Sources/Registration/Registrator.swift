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
    let logger: Logger

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
        logger: Logger = MIRACLTrust.getInstance().logger,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping RegistrationCompletionHandler
    ) throws {
        self.userId = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.activationToken = activationToken.trimmingCharacters(in: .whitespacesAndNewlines)
        self.deviceName = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.pushNotificationsToken = pushNotificationsToken
        self.didRequestPinHandler = didRequestPinHandler

        self.completionHandler = completionHandler
        miraclAPI = api
        self.crypto = crypto

        self.projectId = projectId
        self.userStorage = userStorage
        self.logger = logger

        try validateInput()
    }

    func register() {
        logger.info(
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

        let keyPairResult = crypto.generateKeyPair()
        if let cryptoError = keyPairResult.error {
            callCompletionHandlerWithError(
                error: RegistrationError.registrationFail(cryptoError)
            )
            return
        }

        miraclAPI.registerUser(
            userId: userId,
            activationToken: activationToken,
            deviceName: deviceName,
            publicKey: keyPairResult.publicKey.hex,
            pushToken: pushNotificationsToken
        ) { _, response, error in
            if let error {
                if case let APIError.apiClientError(clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = error, let clientErrorData, clientErrorData.code == INVALID_ACTIVATION_TOKEN {
                    self.callCompletionHandlerWithError(error: RegistrationError.invalidActivationToken)
                    return
                }

                self.callCompletionHandlerWithError(
                    error: RegistrationError.registrationFail(error)
                )
                return
            }

            guard let response else {
                self.logOperation(operation: "registration error with nil response")

                self.callCompletionHandlerWithError(
                    error: RegistrationError.registrationFail(nil)
                )
                return
            }

            if response.projectId != self.projectId {
                self.callCompletionHandlerWithError(error: RegistrationError.projectMismatch)
                return
            }

            if CryptoSupportedEllipticCurves(rawValue: response.curve) == nil {
                self.callCompletionHandlerWithError(error: RegistrationError.unsupportedEllipticCurve)
                return
            }

            if response.secretUrls.isEmpty {
                self.logOperation(operation: "registerUser emtpy secret URLs")

                self.callCompletionHandlerWithError(error: RegistrationError.registrationFail(nil))
                return
            }

            self.getClientSecretShares(
                mpinId: response.mpinId,
                dtas: response.dtas,
                keyPairResult: (keyPairResult.privateKey, keyPairResult.publicKey),
                secretURLs: response.secretUrls
            )
        }
    }

    private func getClientSecretShares(
        mpinId: String,
        dtas: String,
        keyPairResult: (privateKey: Data, publicKey: Data),
        secretURLs: [String]
    ) {
        logOperation(operation: LoggingConstants.registrationGettingClientSecretShares)

        let dispatchGroup = DispatchGroup()
        let writeQueue = DispatchQueue(label: "com.miracl.secretURLsQueue")

        var results = [Data]()
        var secretURLFetchingError: Error?

        let filteredSecretURLs: [String] = Array(secretURLs.prefix(2))

        for secretURL in filteredSecretURLs {
            dispatchGroup.enter()

            guard let clientSecretShareURL = URL(string: secretURL) else {
                logOperation(operation: LoggingConstants.registrationInvalidClientSecretShareURL)
                secretURLFetchingError = RegistrationError.registrationFail(nil)
                dispatchGroup.leave()
                break
            }

            getClientSecretShare(clientSecretShareURL: clientSecretShareURL) { result in
                switch result {
                case let .success(clientSecretShare):
                    writeQueue.async {
                        results.append(clientSecretShare)
                    }
                case let .failure(error):
                    writeQueue.async {
                        secretURLFetchingError = error
                    }
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: writeQueue) {
            if let secretURLFetchingError {
                self.callCompletionHandlerWithError(
                    error: secretURLFetchingError
                )
                return
            }

            self.getClientToken(
                mpinId: mpinId,
                clientSecrets: results,
                dtas: dtas,
                keypair: keyPairResult
            )
        }
    }

    private func getClientSecretShare(
        clientSecretShareURL: URL,
        completionHandler: @escaping (Result<Data, Error>) -> Void
    ) {
        miraclAPI.getClientSecretShare(clientSecretShareURL) { _, response, error in
            if let error {
                if case APIError.executionError = error {
                    self.miraclAPI.getClientSecretShare(clientSecretShareURL) { _, retryResponse, retryError in
                        if let retryResponse {
                            completionHandler(
                                .success(Data(hexString: retryResponse.dvsClientSecret))
                            )
                        } else if let retryError {
                            completionHandler(.failure(RegistrationError.registrationFail(retryError)))
                        } else {
                            completionHandler(.failure(RegistrationError.registrationFail(nil)))
                        }
                    }
                } else {
                    completionHandler(.failure(RegistrationError.registrationFail(error)))
                }
            } else if let response {
                completionHandler(
                    .success(Data(hexString: response.dvsClientSecret))
                )
            } else {
                completionHandler(.failure(RegistrationError.registrationFail(nil)))
            }
        }
    }

    private func getClientToken(
        mpinId: String,
        clientSecrets: [Data],
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

        if clientSecrets.count < 2 {
            callCompletionHandlerWithError(error: RegistrationError.registrationFail(nil))
            return
        }

        let (clientTokenData, tokenCryptoError) =
            crypto.getSigningClientToken(
                clientSecret1: clientSecrets[0],
                clientSecret2: clientSecrets[1],
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
                logger.info(
                    message: LoggingConstants.registrationOverride,
                    category: .registration
                )

                try userStorage.update(user: user)

                DispatchQueue.main.async {
                    self.completionHandler(user, nil)
                }
            } else {
                logger.info(
                    message: LoggingConstants.storageАddAuthenticationIdentity,
                    category: .registration
                )

                try userStorage.add(user: user)

                DispatchQueue.main.async {
                    self.completionHandler(user, nil)
                }
            }

            logger.info(
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
        logger.info(
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
