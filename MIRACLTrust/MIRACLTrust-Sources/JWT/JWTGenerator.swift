import Foundation

struct JWTGenerator: Sendable {
    let user: User
    let miraclAPI: APIBlueprint
    let userStorage: UserStorage
    let completionHandler: JWTCompletionHandler
    let didRequestPinHandler: PinRequestHandler
    let deviceName: String
    let crypto: CryptoBlueprint
    let logger: Logger

    var authenticator: AuthenticatorBlueprint?

    init(
        user: User,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        deviceName: String = MIRACLTrust.getInstance().deviceName,
        userStorage: UserStorage = MIRACLTrust.getInstance().userStorage,
        crypto: CryptoBlueprint = MIRACLTrust.getInstance().crypto,
        logger: Logger = MIRACLTrust.getInstance().logger,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping JWTCompletionHandler
    ) {
        self.user = user
        self.miraclAPI = miraclAPI
        self.deviceName = deviceName
        self.didRequestPinHandler = didRequestPinHandler
        self.userStorage = userStorage
        self.crypto = crypto
        self.logger = logger
        self.completionHandler = completionHandler
    }

    func generate() {
        DispatchQueue.global(qos: .default).async {
            logOperation(operation: LoggingConstants.started)
            authenticate()
        }
    }

    private func authenticate() {
        do {
            if var authenticator = authenticator {
                authenticator.completionHandler = authenticationResult
                authenticator.authenticate()
            } else {
                let authenticator = try Authenticator(
                    user: user,
                    sessionType: .noSession,
                    crypto: crypto,
                    deviceName: deviceName,
                    api: miraclAPI,
                    userStorage: userStorage,
                    scope: ["jwt"],
                    didRequestPinHandler: didRequestPinHandler,
                    completionHandler: authenticationResult
                )
                authenticator.authenticate()
            }
        } catch {
            callCompletionHandler(with: error)
        }
    }

    @Sendable private func authenticationResult(response: AuthenticateResponse?, error: Error?) {
        if let error = error {
            callCompletionHandler(with: error)
            return
        }

        guard let jwt = response?.jwt else {
            callCompletionHandler(with: AuthenticationError.authenticationFail(nil))
            return
        }

        logOperation(operation: LoggingConstants.finished)
        DispatchQueue.main.async {
            completionHandler(jwt, nil)
        }
    }

    private func callCompletionHandler(with error: Error) {
        logOperation(operation: "\(LoggingConstants.finishedWithError) = \(error)")

        DispatchQueue.main.async {
            completionHandler(nil, error)
        }
    }

    private func logOperation(operation: String) {
        logger.info(
            message: "\(operation)",
            category: .jwtGeneration
        )
    }
}
