import Foundation

typealias JWTGenerationResultCompletionHandler = @MainActor @Sendable (Result<String, Error>) -> Void

struct JWTGenerator {
    let user: User
    let miraclAPI: APIBlueprint
    let userStorage: UserStorage
    let completionHandler: JWTGenerationResultCompletionHandler
    let didRequestPinHandler: PinRequestHandler
    let deviceName: String
    let crypto: CryptoBlueprint
    let logger: Logger
    let deviceTagManager: DeviceTagManager

    var authenticator: AuthenticatorBlueprint?

    init(
        user: User,
        miraclAPI: APIBlueprint,
        deviceName: String,
        userStorage: UserStorage,
        crypto: CryptoBlueprint,
        logger: Logger,
        deviceTagManager: DeviceTagManager,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping JWTGenerationResultCompletionHandler
    ) {
        self.user = user
        self.miraclAPI = miraclAPI
        self.deviceName = deviceName
        self.didRequestPinHandler = didRequestPinHandler
        self.userStorage = userStorage
        self.crypto = crypto
        self.logger = logger
        self.deviceTagManager = deviceTagManager
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
                    sessionIdentifier: nil,
                    crypto: crypto,
                    deviceName: deviceName,
                    api: miraclAPI,
                    userStorage: userStorage,
                    logger: logger,
                    scope: ["jwt"],
                    deviceTagManager: deviceTagManager,
                    didRequestPinHandler: didRequestPinHandler,
                    completionHandler: authenticationResult
                )
                authenticator.authenticate()
            }
        } catch {
            callCompletionHandler(with: error)
        }
    }

    @Sendable private func authenticationResult(result: Result<AuthenticateResponse, Error>) {
        do {
            let response = try result.get()
            guard let jwt = response.jwt else {
                callCompletionHandler(with: AuthenticationError.authenticationFail(nil))
                return
            }

            logOperation(operation: LoggingConstants.finished)
            DispatchQueue.main.async {
                completionHandler(.success(jwt))
            }
        } catch {
            callCompletionHandler(with: error)
        }
    }

    private func callCompletionHandler(with error: Error) {
        logOperation(operation: "\(LoggingConstants.finishedWithError) = \(error)")

        DispatchQueue.main.async {
            completionHandler(.failure(error))
        }
    }

    private func logOperation(operation: String) {
        logger.info(
            message: "\(operation)",
            category: .jwtGeneration
        )
    }
}
