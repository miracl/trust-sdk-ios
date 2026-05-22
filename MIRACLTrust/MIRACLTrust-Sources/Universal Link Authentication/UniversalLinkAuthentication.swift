import Foundation

struct UniversalLinkAuthenticator {
    let user: User
    let universalLinkURL: URL
    let miraclAPI: APIBlueprint
    let userStorage: UserStorage
    let crypto: CryptoBlueprint
    let deviceName: String
    let completionHandler: AuthenticationCompletionHandler
    let didRequestPinHandler: PinRequestHandler
    let logger: Logger
    let deviceTagManager: DeviceTagManager

    var authenticator: AuthenticatorBlueprint?

    init(
        user: User,
        universalLinkURL: URL,
        deviceName: String,
        miraclAPI: APIBlueprint,
        crypto: CryptoBlueprint,
        userStorage: UserStorage,
        logger: Logger,
        deviceTagManager: DeviceTagManager,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping AuthenticationCompletionHandler
    ) {
        self.user = user
        self.universalLinkURL = universalLinkURL
        self.deviceName = deviceName
        self.userStorage = userStorage
        self.crypto = crypto
        self.miraclAPI = miraclAPI
        self.logger = logger
        self.deviceTagManager = deviceTagManager
        self.didRequestPinHandler = didRequestPinHandler
        self.completionHandler = completionHandler
    }

    func authenticate() {
        logger.info(
            message: LoggingConstants.started,
            category: .authentication
        )

        guard let urlComponents = URLComponents(url: universalLinkURL, resolvingAgainstBaseURL: false),
              let accessId = urlComponents.fragment,
              !accessId.isEmpty else {
            callCompletionHandler(
                authenticated: false,
                error: AuthenticationError.invalidUniversalLink
            )
            return
        }

        do {
            if var authenticator = authenticator {
                authenticator.completionHandler = authenticationResult
                authenticator.authenticate()
                return
            }

            let authenticator = try Authenticator(
                user: user,
                sessionIdentifier: accessId,
                crypto: crypto,
                deviceName: deviceName,
                api: miraclAPI,
                userStorage: userStorage,
                logger: logger,
                deviceTagManager: deviceTagManager,
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
