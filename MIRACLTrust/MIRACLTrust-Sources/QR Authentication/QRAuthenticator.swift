import Foundation

struct QRAuthenticator {
    let user: User
    let qrCode: String
    let miraclAPI: APIBlueprint
    let userStorage: UserStorage
    let deviceName: String
    let completionHandler: AuthenticationCompletionHandler
    let didRequestPinHandler: PinRequestHandler
    let crypto: CryptoBlueprint
    let logger: Logger
    let deviceTagManager: DeviceTagManager

    var authenticator: AuthenticatorBlueprint?

    init(
        user: User,
        qrCode: String,
        deviceName: String,
        crypto: CryptoBlueprint,
        miraclAPI: APIBlueprint,
        userStorage: UserStorage,
        logger: Logger,
        deviceTagManager: DeviceTagManager,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping AuthenticationCompletionHandler
    ) {
        self.user = user
        self.qrCode = qrCode
        self.deviceName = deviceName
        self.crypto = crypto
        self.userStorage = userStorage
        self.miraclAPI = miraclAPI
        self.didRequestPinHandler = didRequestPinHandler
        self.logger = logger
        self.deviceTagManager = deviceTagManager
        self.completionHandler = completionHandler
    }

    func authenticate() {
        logger.info(
            message: LoggingConstants.started,
            category: .authentication
        )

        guard let urlComponents = URLComponents(string: qrCode),
              let accessId = urlComponents.fragment,
              !accessId.isEmpty else {
            callCompletionHandler(
                authenticated: false,
                error: AuthenticationError.invalidQRCode
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
            category: .registration
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
