import Foundation

struct PushNotificationAuthenticator: Sendable {
    let miraclAPI: APIBlueprint
    let userStorage: UserStorage
    let crypto: CryptoBlueprint
    let deviceName: String
    let completionHandler: AuthenticationCompletionHandler
    let didRequestPinHandler: PinRequestHandler
    let miraclLogger: MIRACLLogger

    var authenticator: AuthenticatorBlueprint?

    init(
        deviceName: String = MIRACLTrust.getInstance().deviceName,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        userStorage: UserStorage = MIRACLTrust.getInstance().userStorage,
        crypto: CryptoBlueprint = MIRACLTrust.getInstance().crypto,
        miraclLogger: MIRACLLogger = MIRACLTrust.getInstance().miraclLogger,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping AuthenticationCompletionHandler
    ) {
        self.deviceName = deviceName
        self.userStorage = userStorage
        self.crypto = crypto
        self.miraclAPI = miraclAPI
        self.miraclLogger = miraclLogger
        self.didRequestPinHandler = didRequestPinHandler
        self.completionHandler = completionHandler
    }

    func authenticate(with payload: [AnyHashable: Any]) {
        guard let userId = payload["userID"] as? String, !userId.isEmpty,
              let projectId = payload["projectID"] as? String, !projectId.isEmpty else {
            callCompletionHandler(
                authenticated: false,
                error: AuthenticationError.invalidPushNotificationPayload
            )
            return
        }

        guard let user = userStorage.getUser(by: userId, projectId: projectId) else {
            callCompletionHandler(
                authenticated: false,
                error: AuthenticationError.userNotFound
            )
            return
        }

        guard let qrCode = payload["qrURL"] as? String,
              let urlComponents = URLComponents(string: qrCode),
              let accessId = urlComponents.fragment, !accessId.isEmpty else {
            callCompletionHandler(
                authenticated: false,
                error: AuthenticationError.invalidPushNotificationPayload
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
