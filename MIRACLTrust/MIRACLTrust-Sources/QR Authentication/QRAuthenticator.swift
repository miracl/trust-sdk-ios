import Foundation

struct QRAuthenticator: Sendable {
    let user: User
    let qrCode: String
    let miraclAPI: APIBlueprint
    let userStorage: UserStorage
    let deviceName: String
    let completionHandler: AuthenticationCompletionHandler
    let didRequestPinHandler: PinRequestHandler
    let crypto: CryptoBlueprint
    let miraclLogger: MIRACLLogger

    var authenticator: AuthenticatorBlueprint?

    init(
        user: User,
        qrCode: String,
        deviceName: String = MIRACLTrust.getInstance().deviceName,
        crypto: CryptoBlueprint = MIRACLTrust.getInstance().crypto,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        userStorage: UserStorage = MIRACLTrust.getInstance().userStorage,
        miraclLogger: MIRACLLogger = MIRACLTrust.getInstance().miraclLogger,
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
        self.miraclLogger = miraclLogger
        self.completionHandler = completionHandler
    }

    func authenticate() {
        miraclLogger.info(
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
