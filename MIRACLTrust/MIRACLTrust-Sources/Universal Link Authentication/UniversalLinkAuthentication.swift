import Foundation

struct UniversalLinkAuthenticator: Sendable {
    let user: User
    let universalLinkURL: URL
    let miraclAPI: APIBlueprint
    let userStorage: UserStorage
    let crypto: CryptoBlueprint
    let deviceName: String
    let completionHandler: AuthenticationCompletionHandler
    let didRequestPinHandler: PinRequestHandler
    let miraclLogger: MIRACLLogger

    var authenticator: AuthenticatorBlueprint?

    init(
        user: User,
        universalLinkURL: URL,
        deviceName: String = MIRACLTrust.getInstance().deviceName,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        crypto: CryptoBlueprint = MIRACLTrust.getInstance().crypto,
        userStorage: UserStorage = MIRACLTrust.getInstance().userStorage,
        miraclLogger: MIRACLLogger = MIRACLTrust.getInstance().miraclLogger,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping AuthenticationCompletionHandler
    ) {
        self.user = user
        self.universalLinkURL = universalLinkURL
        self.deviceName = deviceName
        self.userStorage = userStorage
        self.crypto = crypto
        self.miraclAPI = miraclAPI
        self.miraclLogger = miraclLogger
        self.didRequestPinHandler = didRequestPinHandler
        self.completionHandler = completionHandler
    }

    func authenticate() {
        miraclLogger.info(
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
                accessId: accessId,
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

    @Sendable private func authenticationResult(response: AuthenticateResponse?, error: Error?) {
        miraclLogger.info(
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
            miraclLogger.error(
                message: "\(LoggingConstants.finishedWithError)=\(error)",
                category: .authentication
            )
        }

        DispatchQueue.main.async {
            completionHandler(authenticated, error)
        }
    }
}
