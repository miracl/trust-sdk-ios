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
    let deviceTagManager: DeviceTagManager

    private let pinLengthRange = 4 ... 6

    init(
        userId: String,
        activationToken: String,
        deviceName: String,
        pushNotificationsToken: String? = nil,
        api: APIBlueprint,
        userStorage: UserStorage,
        projectId: String,
        crypto: CryptoBlueprint,
        logger: Logger,
        deviceTagManager: DeviceTagManager,
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
        self.deviceTagManager = deviceTagManager

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
            pushToken: pushNotificationsToken,
            deviceTag: deviceTagManager.deviceTag
        ) { _, response, error in
            if let error {
                if case let APIError.apiClientError(statusCode: _, clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = error, let clientErrorData, clientErrorData.code == INVALID_ACTIVATION_TOKEN {
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

            if response.designatedTAs.isEmpty {
                self.logOperation(operation: "registerUser emtpy designatedTAs array")

                self.callCompletionHandlerWithError(error: RegistrationError.registrationFail(nil))
                return
            }

            self.getTAShareResponses(
                mpinId: response.mpinId,
                designatedTAs: response.designatedTAs,
                keyPairResult: (keyPairResult.privateKey, keyPairResult.publicKey)
            )
        }
    }

    private func getTAShareResponses(
        mpinId: String,
        designatedTAs: [DesignatedTA],
        keyPairResult: (privateKey: Data, publicKey: Data)
    ) {
        logOperation(operation: LoggingConstants.registrationGettingClientSecretShares)

        let dispatchGroup = DispatchGroup()
        let writeQueue = DispatchQueue(label: "com.miracl.secretURLsQueue")

        nonisolated(unsafe) var taShareResponses = [TAShareResponse]()
        nonisolated(unsafe) var taShareResponsesError: Error?

        let filteredTAs: [DesignatedTA] = Array(designatedTAs.prefix(2))
        for designatedTA in filteredTAs {
            dispatchGroup.enter()

            getTAShare(designatedTA: designatedTA, mpinId: mpinId, publicKey: keyPairResult.publicKey) { result in
                switch result {
                case let .success(response):
                    writeQueue.async {
                        taShareResponses.append(response)
                    }
                case let .failure(error):
                    writeQueue.async {
                        taShareResponsesError = error
                    }
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: writeQueue) {
            if let taShareResponsesError {
                self.callCompletionHandlerWithError(
                    error: taShareResponsesError
                )
                return
            }

            self.getClientToken(
                mpinId: mpinId,
                taShareResponses: taShareResponses,
                keypair: keyPairResult
            )
        }
    }

    private func getTAShare(
        designatedTA: DesignatedTA,
        mpinId: String,
        publicKey: Data,
        completionHandler: @escaping @Sendable (Result<TAShareResponse, Error>) -> Void
    ) {
        miraclAPI.getTAShare(
            designatedTA: designatedTA,
            mpinId: mpinId,
            publicKey: publicKey.hex
        ) { _, response, error in
            if let response {
                completionHandler(.success(response))
            } else if let error {
                completionHandler(.failure(RegistrationError.registrationFail(error)))
            } else {
                completionHandler(.failure(RegistrationError.registrationFail(nil)))
            }
        }
    }

    private func getClientToken(
        mpinId: String,
        taShareResponses: [TAShareResponse],
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

        let clientSecretsShares = taShareResponses.map { response in
            Data(hexString: response.share)
        }

        if clientSecretsShares.count < 2 {
            callCompletionHandlerWithError(error: RegistrationError.registrationFail(nil))
            return
        }

        let (clientTokenData, tokenCryptoError) =
            crypto.getSigningClientToken(
                clientSecret1: clientSecretsShares[0],
                clientSecret2: clientSecretsShares[1],
                privateKey: keypair.privateKey,
                signingMpinId: combinedMpinId,
                pinCode: pin
            )

        if let tokenCryptoError {
            callCompletionHandlerWithError(error: RegistrationError.registrationFail(tokenCryptoError))
            return
        }

        if clientTokenData.isEmpty {
            callCompletionHandlerWithError(error: RegistrationError.registrationFail(nil))
            return
        }

        do {
            let dtasArray = taShareResponses.map { response in
                response.node
            }
            let dtas = try JSONEncoder().encode(dtasArray).base64EncodedString()

            addOrUpdateUser(
                pinLength: pinLength,
                mpinId: mpinId,
                clientTokenData: clientTokenData,
                dtas: dtas,
                publicKey: publicKey
            )
        } catch {
            callCompletionHandlerWithError(error: RegistrationError.registrationFail(error))
        }
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

            if try userStorage.getUser(
                by: userId,
                projectId: projectId
            ) != nil {
                logger.info(
                    message: LoggingConstants.registrationOverride,
                    category: .registration
                )

                try userStorage.update(user: user.toUserDTO())

                DispatchQueue.main.async {
                    self.completionHandler(user, nil)
                }
            } else {
                logger.info(
                    message: LoggingConstants.storageАddAuthenticationIdentity,
                    category: .registration
                )

                try userStorage.add(user: user.toUserDTO())

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
        let pinController = PinController()
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            self.didRequestPinHandler { pin in
                pinController.updatePin(pin)
                semaphore.signal()
            }
        }

        _ = semaphore.wait(timeout: .distantFuture)

        guard let pinCode = pinController.readPin() else {
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
