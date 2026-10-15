import Foundation

typealias CrossDeviceSessionAuthenticatorResultCompletionHandler = @MainActor @Sendable (Result<Void, Error>) -> Void

struct CrossDeviceSessionAuthenticator {
    let user: User
    let crossDeviceSession: CrossDeviceSession
    let miraclAPI: APIBlueprint
    let userStorage: UserStorage
    let crypto: CryptoBlueprint
    let deviceName: String
    let completionHandler: CrossDeviceSessionAuthenticatorResultCompletionHandler
    let didRequestPinHandler: PinRequestHandler
    let logger: Logger
    let deviceTagManager: DeviceTagManager

    var authenticator: AuthenticatorBlueprint?

    init(
        user: User,
        crossDeviceSession: CrossDeviceSession,
        miraclAPI: APIBlueprint,
        userStorage: UserStorage,
        crypto: CryptoBlueprint,
        deviceName: String,
        logger: Logger,
        deviceTagManager: DeviceTagManager,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping CrossDeviceSessionAuthenticatorResultCompletionHandler
    ) {
        self.user = user
        self.crossDeviceSession = crossDeviceSession
        self.miraclAPI = miraclAPI
        self.userStorage = userStorage
        self.crypto = crypto
        self.deviceName = deviceName
        self.completionHandler = completionHandler
        self.didRequestPinHandler = didRequestPinHandler
        self.deviceTagManager = deviceTagManager
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
                logger: logger,
                deviceTagManager: deviceTagManager,
                didRequestPinHandler: didRequestPinHandler,
                completionHandler: authenticationResult
            )

            authenticator.authenticate()
        } catch {
            callCompletionHandler(
                error: error
            )
        }
    }

    // MARK: Private

    @Sendable private func authenticationResult(result: Result<AuthenticateResponse, Error>) {
        logger.info(
            message: LoggingConstants.finished,
            category: .authentication
        )

        switch result {
        case .success:
            DispatchQueue.main.async {
                completionHandler(.success(()))
            }
        case let .failure(error):
            callCompletionHandler(
                error: error
            )
        }
    }

    private func callCompletionHandler(
        error: Error
    ) {
        logger.error(
            message: "\(LoggingConstants.finishedWithError)=\(error)",
            category: .authentication
        )
        DispatchQueue.main.async {
            completionHandler(.failure(error))
        }
    }
}
