import Foundation

struct Signer: Sendable {
    let messageHash: Data
    let user: User
    let didRequestSigningPinHandler: PinRequestHandler
    let completionHandler: SigningCompletionHandler
    let crypto: CryptoBlueprint
    let miraclAPI: APIBlueprint
    let userStorage: UserStorage
    let signingSessionDetails: SigningSessionDetails?
    let miraclLogger: MIRACLLogger

    var authenticator: AuthenticatorBlueprint?

    init(messageHash: Data,
         user: User,
         signingSessionDetails: SigningSessionDetails? = nil,
         miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
         userStorage: UserStorage = MIRACLTrust.getInstance().userStorage,
         crypto: CryptoBlueprint = MIRACLTrust.getInstance().crypto,
         logger: MIRACLLogger = MIRACLTrust.getInstance().miraclLogger,
         didRequestSigningPinHandler: @escaping PinRequestHandler,
         completionHandler: @escaping SigningCompletionHandler) throws {
        self.messageHash = messageHash
        self.user = user
        self.signingSessionDetails = signingSessionDetails
        self.didRequestSigningPinHandler = didRequestSigningPinHandler
        self.crypto = crypto
        self.completionHandler = completionHandler
        self.miraclAPI = miraclAPI
        self.userStorage = userStorage
        miraclLogger = logger

        try validateInput()
    }

    func sign() {
        miraclLogger.info(
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
                    accessId: nil,
                    crypto: crypto,
                    api: MIRACLTrust.getInstance().miraclAPI,
                    scope: ["dvs-auth"],
                    didRequestPinHandler: { processPinHandler in
                        processPinHandler(pinCode)
                    }, completionHandler: { response, error in
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
        let user = userStorage.getUser(by: user.userId, projectId: user.projectId) ?? user
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
            signatureHash: messageHash.hex
        )

        if let signingSessionDetails {
            completeSigningSession(
                signingSessionDetails: signingSessionDetails,
                signature: signature,
                timestamp: timestamp
            )
        } else {
            miraclLogger.info(
                message: LoggingConstants.finished,
                category: .signing
            )

            let signingResult = SigningResult(signature: signature, timestamp: timestamp)
            callCompletionHandler(signingResult: signingResult)
        }
    }

    private func completeSigningSession(
        signingSessionDetails: SigningSessionDetails,
        signature: Signature,
        timestamp: Date
    ) {
        miraclAPI.updateSigningSession(
            identifier: signingSessionDetails.sessionId,
            signature: signature,
            timestamp: timestamp
        ) { _, responseObject, error in
            if let error {
                if case let APIError.apiClientError(clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = error, let clientErrorData, clientErrorData.code == INVALID_REQUEST_PARAMETERS, let context = clientErrorData.context, context["params"] == "id" {
                    callCompletionHandler(
                        error: SigningError.invalidSigningSession
                    )
                    return
                }

                callCompletionHandler(
                    error: SigningError.signingFail(error)
                )
                return
            }

            guard let responseObject = responseObject else {
                callCompletionHandler(
                    error: SigningError.signingFail(nil)
                )
                return
            }

            let status = SigningSessionStatus.signingSessionStatus(
                from: responseObject.status
            )

            switch status {
            case .active:
                callCompletionHandler(
                    error: SigningError.invalidSigningSession
                )
            case .signed:
                miraclLogger.info(
                    message: LoggingConstants.finished,
                    category: .signing
                )

                let signingResult = SigningResult(signature: signature, timestamp: timestamp)
                callCompletionHandler(signingResult: signingResult)
            }
        }
    }

    private func callCompletionHandler(
        signingResult: SigningResult? = nil,
        error: Error? = nil
    ) {
        if let error {
            miraclLogger.error(
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

        if let signingSessionDetails, signingSessionDetails.sessionId.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            throw SigningError.invalidSigningSessionDetails
        }
    }

    private func logOperation(operation: String) {
        miraclLogger.info(
            message: "\(operation)",
            category: .signingRegistration
        )
    }

    private func getPinCode() -> Result<String, SigningError> {
        nonisolated(unsafe) var userEnteredPin: String?
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            didRequestSigningPinHandler { pin in
                userEnteredPin = pin
                semaphore.signal()
            }
        }

        _ = semaphore.wait(timeout: .distantFuture)

        guard let pinCode = userEnteredPin else {
            return .failure(.pinCancelled)
        }

        if pinCode.count != user.pinLength {
            return .failure(.invalidPin)
        }

        return .success(pinCode)
    }
}
