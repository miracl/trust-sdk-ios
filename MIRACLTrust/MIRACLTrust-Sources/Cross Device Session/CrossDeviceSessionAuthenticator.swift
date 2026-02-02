import Foundation

struct CrossDeviceSessionAuthenticator: Sendable {
    let user: User
    let crossDeviceSession: CrossDeviceSession
    let miraclAPI: APIBlueprint
    let userStorage: UserStorage
    let crypto: CryptoBlueprint
    let deviceName: String
    let completionHandler: AuthenticationCompletionHandler
    let didRequestPinHandler: PinRequestHandler
    let logger: Logger

    var authenticator: AuthenticatorBlueprint?

    init(
        user: User,
        crossDeviceSession: CrossDeviceSession,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        userStorage: UserStorage = MIRACLTrust.getInstance().userStorage,
        crypto: CryptoBlueprint = MIRACLTrust.getInstance().crypto,
        deviceName: String = MIRACLTrust.getInstance().deviceName,
        logger: Logger = MIRACLTrust.getInstance().logger,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping AuthenticationCompletionHandler
    ) {
        self.user = user
        self.crossDeviceSession = crossDeviceSession
        self.miraclAPI = miraclAPI
        self.userStorage = userStorage
        self.crypto = crypto
        self.deviceName = deviceName
        self.completionHandler = completionHandler
        self.didRequestPinHandler = didRequestPinHandler
        self.logger = logger
    }

    func authenticate() {
        logger.info(
            message: LoggingConstants.started,
            category: .authentication
        )

        DispatchQueue.global().async {
            startAuthentication()
        }
    }

    func startAuthentication() {
        do {
            if var authenticator = authenticator {
                authenticator.completionHandler = authenticationResult
                authenticator.authenticate()
                return
            }

            let authenticator = try Authenticator(
                user: user,
                sessionIdentifier: crossDeviceSession.sessionId,
                crypto: crypto,
                deviceName: deviceName,
                api: miraclAPI,
                userStorage: userStorage,
                didRequestPinHandler: didRequestPinHandler,
                completionHandler: authenticationResult
            )

            authenticator.authenticate()
        } catch {
            callCompletionHandler(
                authenticated: false,
                error: error
            )
        }
    }

    // MARK: Private

    @Sendable private func authenticationResult(response: AuthenticateResponse?, error: Error?) {
        logger.info(
            message: LoggingConstants.finished,
            category: .authentication
        )

        if response != nil {
            callCompletionHandler(authenticated: true)
        } else {
            callCompletionHandler(
                authenticated: false,
                error: error
            )
        }
    }

    private func callCompletionHandler(
        authenticated: Bool,
        error: Error? = nil
    ) {
        if let error {
            logger.error(
                message: "\(LoggingConstants.finishedWithError)=\(error)",
                category: .authentication
            )
        }

        DispatchQueue.main.async {
            completionHandler(authenticated, error)
        }
    }
}
