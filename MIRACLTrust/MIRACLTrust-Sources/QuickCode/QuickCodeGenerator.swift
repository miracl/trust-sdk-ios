import Foundation

let LIMITED_QUICKCODE_GENERATION = "LIMITED_QUICKCODE_GENERATION"

struct QuickCodeGenerator: Sendable {
    let user: User
    let completionHandler: QuickCodeCompletionHandler
    let didRequestPinHandler: PinRequestHandler
    let api: APIBlueprint
    let deviceName: String
    let storage: UserStorage
    let crypto: CryptoBlueprint
    let miraclLogger: MIRACLLogger

    var authenticator: AuthenticatorBlueprint?

    init(
        user: User,
        api: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        deviceName: String = MIRACLTrust.getInstance().deviceName,
        storage: UserStorage = MIRACLTrust.getInstance().userStorage,
        crypto: CryptoBlueprint = MIRACLTrust.getInstance().crypto,
        miraclLogger: MIRACLLogger = MIRACLTrust.getInstance().miraclLogger,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping QuickCodeCompletionHandler
    ) {
        self.user = user
        self.api = api
        self.deviceName = deviceName
        self.storage = storage
        self.crypto = crypto
        self.miraclLogger = miraclLogger
        self.didRequestPinHandler = didRequestPinHandler
        self.completionHandler = completionHandler
    }

    func generate() {
        miraclLogger.info(
            message: LoggingConstants.started,
            category: .quickCode
        )

        if var authenticator = authenticator {
            authenticator.completionHandler = authenticationResult
            authenticator.authenticate()
        } else {
            do {
                let authenticator = try Authenticator(
                    user: user,
                    accessId: nil,
                    crypto: crypto,
                    deviceName: deviceName,
                    api: api,
                    userStorage: storage,
                    scope: ["reg-code"],
                    didRequestPinHandler: didRequestPinHandler,
                    completionHandler: authenticationResult
                )
                authenticator.authenticate()
            } catch {
                callCompletionHandler(with: QuickCodeError.generationFail(error))
            }
        }
    }

    @Sendable func authenticationResult(response: AuthenticateResponse?, error: Error?) {
        if let error = error {
            if case let AuthenticationError.authenticationFail(authError) = error,
               let authError = authError as? APIError,
               case let APIError.apiClientError(clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = authError,
               clientErrorData?.code == LIMITED_QUICKCODE_GENERATION {
                callCompletionHandler(with: QuickCodeError.limitedQuickCodeGeneration)
            } else if case AuthenticationError.revoked = error {
                callCompletionHandler(with: QuickCodeError.revoked)
            } else if case AuthenticationError.unsuccessfulAuthentication = error {
                callCompletionHandler(with: QuickCodeError.unsuccessfulAuthentication)
            } else if case AuthenticationError.invalidPin = error {
                callCompletionHandler(with: QuickCodeError.invalidPin)
            } else if case AuthenticationError.pinCancelled = error {
                callCompletionHandler(with: QuickCodeError.pinCancelled)
            } else {
                callCompletionHandler(with: QuickCodeError.generationFail(error))
            }
            return
        }

        guard let jwt = response?.jwt else {
            callCompletionHandler(with: QuickCodeError.generationFail(nil))
            return
        }

        executeVerificationRequest(for: jwt)
    }

    private func executeVerificationRequest(
        for jwt: String
    ) {
        miraclLogger.info(
            message: LoggingConstants.quickCodeVerificationStarted,
            category: .quickCode
        )

        api.quickCodeVerificationRequest(
            projectId: user.projectId,
            jwt: jwt,
            deviceName: deviceName
        ) { _, response, error in

            if let response {
                let quickCode = QuickCode(
                    code: response.code,
                    expireTime: response.expireTime,
                    ttlSeconds: response.ttlSeconds
                )

                miraclLogger.info(
                    message: LoggingConstants.finished,
                    category: .quickCode
                )

                DispatchQueue.main.async {
                    completionHandler(quickCode, nil)
                }
            } else if let error {
                callCompletionHandler(with: QuickCodeError.generationFail(error))
            } else {
                callCompletionHandler(with: QuickCodeError.generationFail(nil))
            }
        }
    }

    private func callCompletionHandler(with error: Error) {
        DispatchQueue.main.async {
            miraclLogger.info(
                message: "\(LoggingConstants.finishedWithError) = \(error)",
                category: .quickCode
            )

            completionHandler(nil, error)
        }
    }

    private func logOperation(operation: String) {
        miraclLogger.info(
            message: "\(operation)",
            category: .quickCode
        )
    }
}
