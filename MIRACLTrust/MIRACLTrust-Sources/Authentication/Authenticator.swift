import Foundation

let MPINID_EXPIRED = "MPINID_EXPIRED"
let EXPIRED_MPINID = "EXPIRED_MPINID"

let REVOKED_MPINID = "REVOKED_MPINID"
let MPINID_REVOKED = "MPINID_REVOKED"

let INVALID_AUTH = "INVALID_AUTH"
let UNSUCCESSFUL_AUTHENTICATION = "UNSUCCESSFUL_AUTHENTICATION"

let INVALID_AUTH_SESSION = "INVALID_AUTH_SESSION"
let INVALID_AUTHENTICATION_SESSION = "INVALID_AUTHENTICATION_SESSION"

struct Authenticator: Sendable, AuthenticatorBlueprint {
    let user: User
    let didRequestPinHandler: PinRequestHandler
    let accessId: String?
    let scope: [String]
    let miraclAPI: APIBlueprint
    let crypto: CryptoBlueprint
    let userStorage: UserStorage
    let deviceName: String
    let miraclLogger: MIRACLLogger

    var completionHandler: AuthenticateCompletionHandler

    init(user: User,
         accessId: String?,
         crypto: CryptoBlueprint = MIRACLTrust.getInstance().crypto,
         deviceName: String = MIRACLTrust.getInstance().deviceName,
         api: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
         userStorage: UserStorage = MIRACLTrust.getInstance().userStorage,
         miraclLogger: MIRACLLogger = MIRACLTrust.getInstance().miraclLogger,
         scope: [String] = ["oidc"],
         didRequestPinHandler: @escaping PinRequestHandler,
         completionHandler: @escaping AuthenticateCompletionHandler) throws {
        self.user = user
        self.accessId = accessId?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.didRequestPinHandler = didRequestPinHandler
        self.completionHandler = completionHandler
        miraclAPI = api
        self.scope = scope
        self.crypto = crypto
        self.userStorage = userStorage
        self.deviceName = deviceName
        self.miraclLogger = miraclLogger

        try validateInput()
    }

    func authenticate() {
        miraclLogger.info(
            message: LoggingConstants.started,
            category: .authentication
        )

        DispatchQueue.global(qos: .default).async {
            updateCodeStatus()

            clientPass1()
        }
    }

    private func updateCodeStatus() {
        guard let accessId = accessId else {
            return
        }

        miraclLogger.info(
            message: LoggingConstants.updatingCodeStatus,
            category: .authentication
        )

        miraclAPI.updateCodeStatus(
            accessId: accessId,
            userId: user.userId,
            completionHandler: { _, _, _ in }
        )
    }

    private func clientPass1() {
        logOperation(operation: LoggingConstants.clientPass1)

        nonisolated(unsafe) var userEnteredPin: String?
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            didRequestPinHandler { pin in
                userEnteredPin = pin
                semaphore.signal()
            }
        }

        _ = semaphore.wait(timeout: .distantFuture)

        guard let pinCode = userEnteredPin else {
            callCompletionHandler(with: AuthenticationError.pinCancelled)
            return
        }

        guard let pin = Int32(pinCode) else {
            callCompletionHandler(with: AuthenticationError.invalidPin)
            return
        }

        if pinCode.count != user.pinLength {
            callCompletionHandler(with: AuthenticationError.invalidPin)
            return
        }

        var combinedMpinId = user.mpinId
        if let publicKey = user.publicKey {
            combinedMpinId.append(publicKey)
        }

        let (u, x, s, clientPass1Error) = crypto.clientPass1(
            mpinId: combinedMpinId,
            token: user.token,
            pinCode: pin
        )

        if let clientPass1Error = clientPass1Error {
            callCompletionHandler(with: AuthenticationError.authenticationFail(clientPass1Error))
            return
        }

        serverPass1(u: u, x: x, s: s, pinCode: pinCode)
    }

    private func serverPass1(u: Data, x: Data, s: Data, pinCode: String) {
        logOperation(operation: LoggingConstants.serverPass1)

        var pkHex: String?
        if let publicKey = user.publicKey {
            if !publicKey.isEmpty {
                pkHex = publicKey.hex
            }
        }

        miraclAPI.pass1(
            for: user.dtas,
            mpinId: user.mpinId.hex,
            publicKey: pkHex,
            uValue: u.hex,
            scope: scope
        ) { apiCallResult, pass1Response, error in
            if apiCallResult == .failed, let error = error {
                logOperation(operation: "Pass1 error = \(error)")

                if case let APIError.apiClientError(clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = error {
                    if let clientErrorData, clientErrorData.code == MPINID_EXPIRED || clientErrorData.code == EXPIRED_MPINID {
                        let user = user.revoke()

                        try? userStorage.update(user: user)

                        callCompletionHandler(with: AuthenticationError.revoked)
                        return
                    }
                }

                callCompletionHandler(with: AuthenticationError.authenticationFail(error))
                return
            }

            let challengeData = Data(hexString: pass1Response?.challenge ?? "")
            clientPass2(
                xValue: x,
                yValue: challengeData,
                sValue: s,
                pinCode: pinCode
            )
        }
    }

    private func clientPass2(xValue: Data, yValue: Data, sValue: Data, pinCode: String) {
        logOperation(operation: LoggingConstants.clientPass2)

        let (vBytes, cryptoError) = crypto.clientPass2(xValue: xValue, yValue: yValue, sValue: sValue)

        if let cryptoError = cryptoError {
            callCompletionHandler(
                with: AuthenticationError.authenticationFail(cryptoError)
            )
            return
        }

        serverPass2(vBytes: vBytes, pinCode: pinCode)
    }

    func serverPass2(vBytes: Data, pinCode: String) {
        miraclAPI.pass2(
            for: user.mpinId.hex,
            accessId: accessId,
            vValue: vBytes.hex
        ) { apiCallResult, response, error in

            if apiCallResult == .failed, let error = error {
                logOperation(operation: "Server Pass2 Error = \(error)")

                callCompletionHandler(
                    with: AuthenticationError.authenticationFail(error)
                )
                return
            }

            guard let response else {
                callCompletionHandler(with: AuthenticationError.authenticationFail(nil))
                return
            }

            authenticate(authOTT: response.authOTT, pinCode: pinCode)
        }
    }

    func authenticate(authOTT: String, pinCode: String) {
        logOperation(operation: LoggingConstants.authenticateRequest)

        miraclAPI.authenticate(authOTT: authOTT) { apiCallResult, authenticateResponse, error in
            if apiCallResult == .failed, let error = error {
                logOperation(operation: "Authenticate error = \(error)")

                if case let APIError.apiClientError(clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = error {
                    if let clientErrorData {
                        switch clientErrorData.code {
                        case MPINID_REVOKED, REVOKED_MPINID:
                            let user = user.revoke()

                            try? userStorage.update(user: user)

                            callCompletionHandler(with: AuthenticationError.revoked)
                            return
                        case INVALID_AUTH_SESSION, INVALID_AUTHENTICATION_SESSION:
                            callCompletionHandler(with: AuthenticationError.invalidAuthenticationSession)
                            return
                        case INVALID_AUTH, UNSUCCESSFUL_AUTHENTICATION:
                            callCompletionHandler(with: AuthenticationError.unsuccessfulAuthentication)
                            return
                        default:
                            break
                        }
                    }
                }
                logOperation(operation: LoggingConstants.authenticateError + "= \(error)")

                callCompletionHandler(
                    with: AuthenticationError.authenticationFail(error)
                )
                return
            }

            guard let authenticateResponse = authenticateResponse else {
                callCompletionHandler(with: AuthenticationError.authenticationFail(nil))
                return
            }

            if let renewSecretResponse =
                authenticateResponse.renewSecretResponse {
                logOperation(operation: LoggingConstants.wamStarted)
                renewRegistration(
                    renewSecretResponse: renewSecretResponse,
                    authenticateResponse: authenticateResponse,
                    pinCode: pinCode
                )
            } else {
                finishAuthentication(with: authenticateResponse)
            }
        }
    }

    private func renewRegistration(
        renewSecretResponse: RenewSecretResponse,
        authenticateResponse: AuthenticateResponse,
        pinCode: String
    ) {
        let registrator = Registrator(
            userId: user.userId,
            api: miraclAPI,
            userStorage: userStorage,
            projectId: user.projectId,
            crypto: crypto,
            didRequestPinHandler: { processPinHandler in
                processPinHandler(pinCode)
            }, completionHandler: { updatedUser, error in
                if let updatedUser = updatedUser {
                    logOperation(operation: LoggingConstants.wamFinished)
                    redoAuthentication(with: updatedUser, pinCode: pinCode)
                } else if let error = error {
                    logOperation(
                        operation: "\(LoggingConstants.wamUserError) = \(error)"
                    )
                    finishAuthentication(with: authenticateResponse)
                }
            }
        )

        registrator.getWAMSecret(dvsRegistrationToken: renewSecretResponse.token ?? "")
    }

    private func finishAuthentication(with response: AuthenticateResponse) {
        DispatchQueue.main.async {
            miraclLogger.info(
                message: LoggingConstants.finished,
                category: .authentication
            )

            completionHandler(response, nil)
        }
    }

    private func redoAuthentication(with updatedUser: User, pinCode: String) {
        do {
            logOperation(operation: LoggingConstants.wamReAuthentication)

            let updatedAuthenticator = try Authenticator(
                user: updatedUser,
                accessId: accessId,
                crypto: crypto,
                deviceName: deviceName,
                api: miraclAPI,
                userStorage: userStorage,
                scope: scope,
                didRequestPinHandler: { pinHandler in
                    pinHandler(pinCode)
                }, completionHandler: { updatedAuthenticationResponse, updatedAuthenticationError in
                    if let updatedAuthenticationResponse = updatedAuthenticationResponse {
                        finishAuthentication(with: updatedAuthenticationResponse)
                    } else if let updatedAuthenticationError = updatedAuthenticationError {
                        callCompletionHandler(with: updatedAuthenticationError)
                    }
                }
            )
            updatedAuthenticator.authenticate()
        } catch let updateAuthenticationError {
            self.callCompletionHandler(with: updateAuthenticationError)
        }
    }

    // MARK: Private

    private func validateInput() throws {
        if user.revoked {
            throw AuthenticationError.revoked
        }

        if user.projectId.isEmpty || user.userId.isEmpty {
            throw AuthenticationError.invalidUserData
        }

        if user.emptyUser() {
            throw AuthenticationError.invalidUserData
        }
    }

    private func callCompletionHandler(with error: Error) {
        DispatchQueue.main.async {
            completionHandler(nil, error)
        }
    }

    private func logOperation(operation: String) {
        miraclLogger.info(
            message: "\(operation)",
            category: .authentication
        )
    }
}
