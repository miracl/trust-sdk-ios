import Foundation

struct Signer {
    let messageHash: Data
    let user: User
    let didRequestSigningPinHandler: PinRequestHandler
    let completionHandler: SigningCompletionHandler
    let crypto: CryptoBlueprint
    let miraclAPI: APIBlueprint
    let userStorage: UserStorage
    let sessionIdentifier: String?
    let logger: Logger
    let deviceName: String
    let deviceTagManager: DeviceTagManager

    var authenticator: AuthenticatorBlueprint?

    init(
        messageHash: Data,
        sessionIdentifier: String?,
        user: User,
        miraclAPI: APIBlueprint,
        userStorage: UserStorage,
        crypto: CryptoBlueprint,
        logger: Logger,
        deviceName: String,
        deviceTagManager: DeviceTagManager,
        didRequestSigningPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping SigningCompletionHandler
    ) throws {
        self.messageHash = messageHash
        self.user = user
        self.sessionIdentifier = sessionIdentifier
        self.didRequestSigningPinHandler = didRequestSigningPinHandler
        self.crypto = crypto
        self.completionHandler = completionHandler
        self.miraclAPI = miraclAPI
        self.userStorage = userStorage
        self.logger = logger
        self.deviceTagManager = deviceTagManager
        self.deviceName = deviceName

        try validateInput()
    }

    func sign() {
        logger.info(
            message: LoggingConstants.started,
            category: .signing
        )

        DispatchQueue.global().async {
            signingAuthenticate()
        }
    }

    private func signingAuthenticate() {
        logOperation(operation: LoggingConstants.signingAuthentication)

        let result = getPinCode()
        let pinCode: String

        switch result {
        case let .success(enteredPin):
            pinCode = enteredPin
        case let .failure(error):
            callCompletionHandler(error: error)
            return
        }

        guard let pin = Int32(pinCode) else {
            callCompletionHandler(error: SigningError.invalidPin)
            return
        }

        if var authenticator = authenticator {
            authenticator.completionHandler = { response, error in
                handleAuthenticationResult(
                    response: response,
                    error: error,
                    pin: pin
                )
            }
            authenticator.authenticate()
        } else {
            do {
                let authenticator = try Authenticator(
                    user: user,
                    sessionIdentifier: nil,
                    crypto: crypto,
                    deviceName: deviceName,
                    api: miraclAPI,
                    userStorage: userStorage,
                    logger: logger,
                    scope: ["dvs-auth"],
                    deviceTagManager: deviceTagManager,
                    didRequestPinHandler: { processPinHandler in
                        processPinHandler(pinCode)
                    },
                    completionHandler: { response, error in
                        handleAuthenticationResult(
                            response: response,
                            error: error,
                            pin: pin
                        )
                    }
                )
                authenticator.authenticate()
            } catch {
                callCompletionHandler(error: SigningError.signingFail(error))
            }
        }
    }

    private func handleAuthenticationResult(
        response: AuthenticateResponse?,
        error: Error?,
        pin: Int32
    ) {
        if response != nil {
            signMessage(with: pin)
        } else if let error = error {
            if case AuthenticationError.revoked = error {
                callCompletionHandler(error: SigningError.revoked)
            } else if case AuthenticationError.unsuccessfulAuthentication = error {
                callCompletionHandler(error: SigningError.unsuccessfulAuthentication)
            } else {
                callCompletionHandler(error: SigningError.signingFail(error))
            }
        }
    }

    private func signMessage(with pin: Int32) {
        logOperation(operation: LoggingConstants.signingExecution)

        // User could be updated from WaM.
        let userDTO = try? userStorage.getUser(by: user.userId, projectId: user.projectId)
        let user = userDTO?.toUser() ?? user

        let timestamp = Date()

        guard let publicKey = user.publicKey else {
            callCompletionHandler(error: SigningError.emptyPublicKey)
            return
        }

        var combinedMpinId = user.mpinId
        combinedMpinId.append(publicKey)

        let (uData, vData, cryptoError) = crypto.sign(
            message: messageHash,
            signingMpinId: combinedMpinId,
            signingToken: user.token,
            pinCode: pin,
            timestamp: Int32(timestamp.timeIntervalSince1970)
        )

        if let cryptoError = cryptoError {
            callCompletionHandler(error: SigningError.signingFail(cryptoError))
            return
        }

        if uData.isEmpty || vData.isEmpty {
            callCompletionHandler(error: SigningError.signingFail(nil))
            return
        }

        let signature = Signature(
            mpinId: user.mpinId.hex,
            U: uData.hex,
            V: vData.hex,
            publicKey: publicKey.hex,
            dtas: user.dtas,
            signatureHash: messageHash.hex,
            timestamp: timestamp
        )

        if let sessionIdentifier {
            completeCrossDeviceSession(
                sessionId: sessionIdentifier,
                signature: signature,
                timestamp: timestamp
            )
        } else {
            logger.info(
                message: LoggingConstants.finished,
                category: .signing
            )

            let signingResult = SigningResult(signature: signature, timestamp: timestamp)
            callCompletionHandler(signingResult: signingResult)
        }
    }

    private func completeCrossDeviceSession(
        sessionId: String,
        signature: Signature,
        timestamp: Date
    ) {
        do {
            let signatureData = try JSONEncoder().encode(signature)
            let encodedSignature = signatureData.base64EncodedString()

            miraclAPI.updateCrossDeviceSessionForSigning(
                sessionId: sessionId,
                signature: encodedSignature
            ) { _, _, error in
                if let error {
                    callCompletionHandler(error: SigningError.signingFail(error))
                } else {
                    let signingResult = SigningResult(signature: signature, timestamp: timestamp)
                    callCompletionHandler(signingResult: signingResult)
                }
            }

        } catch {
            callCompletionHandler(signingResult: nil, error: error)
        }
    }

    private func callCompletionHandler(
        signingResult: SigningResult? = nil,
        error: Error? = nil
    ) {
        if let error {
            logger.error(
                message: "\(LoggingConstants.finishedWithError)=\(error)",
                category: .signing
            )
        }

        DispatchQueue.main.async {
            completionHandler(signingResult, error)
        }
    }

    private func validateInput() throws {
        if user.revoked {
            throw SigningError.revoked
        }

        if user.emptyUser() {
            throw SigningError.invalidUserData
        }

        if messageHash.isEmpty {
            throw SigningError.emptyMessageHash
        }

        if let publicKey = user.publicKey, publicKey.isEmpty {
            throw SigningError.emptyPublicKey
        }
    }

    private func logOperation(operation: String) {
        logger.info(
            message: "\(operation)",
            category: .signingRegistration
        )
    }

    private func getPinCode() -> Result<String, SigningError> {
        let semaphore = DispatchSemaphore(value: 0)
        let pinController = PinController()

        DispatchQueue.main.async {
            didRequestSigningPinHandler { pin in
                pinController.updatePin(pin)
                semaphore.signal()
            }
        }

        _ = semaphore.wait(timeout: .distantFuture)

        guard let pinCode = pinController.readPin() else {
            return .failure(.pinCancelled)
        }

        if pinCode.count != user.pinLength {
            return .failure(.invalidPin)
        }

        return .success(pinCode)
    }
}
