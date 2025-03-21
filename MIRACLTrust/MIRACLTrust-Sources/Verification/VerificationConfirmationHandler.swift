import Foundation

let INVALID_VERIFICATION_CODE = "INVALID_VERIFICATION_CODE"
let UNSUCCESSFUL_VERIFICATION = "UNSUCCESSFUL_VERIFICATION"

struct VerificationConfirmationHandler: Sendable {
    let miraclAPI: APIBlueprint
    let completionHandler: ActivationTokenCompletionHandler
    let activationCode: String?
    let userId: String?
    let miraclLogger: MIRACLLogger

    init(
        verificationURL: URL,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        miraclLogger: MIRACLLogger = MIRACLTrust.getInstance().miraclLogger,
        completionHandler: @escaping ActivationTokenCompletionHandler
    ) throws {
        self.miraclAPI = miraclAPI
        self.completionHandler = completionHandler

        let components = URLComponents(
            url: verificationURL,
            resolvingAgainstBaseURL: false
        )

        activationCode = VerificationConfirmationHandler.getActivationCode(components: components)
        userId = VerificationConfirmationHandler.getUserId(components: components)
        self.miraclLogger = miraclLogger

        try validateInput()
    }

    init(
        userId: String,
        activationCode: String,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        miraclLogger: MIRACLLogger = MIRACLTrust.getInstance().miraclLogger,
        completionHandler: @escaping ActivationTokenCompletionHandler
    ) throws {
        self.miraclAPI = miraclAPI
        self.completionHandler = completionHandler
        self.activationCode = activationCode
        self.userId = userId
        self.miraclLogger = miraclLogger

        try validateInput()
    }

    func handle() {
        logOperation(operation: LoggingConstants.started)

        logOperation(operation: LoggingConstants.verificationConfirmationUserId)
        guard let userId = userId else {
            callCompletionHandler(
                with: ActivationTokenError.emptyUserId
            )
            return
        }

        logOperation(operation: LoggingConstants.verificationConfirmationActivationToken)
        guard let activationCode = activationCode else {
            callCompletionHandler(
                with: ActivationTokenError
                    .emptyVerificationCode
            )
            return
        }

        logOperation(operation: LoggingConstants.verificationConfirmationRequest)

        miraclAPI.confirmVerificationRequest(
            userId: userId,
            code: activationCode
        ) { apiCallResult, response, error in

            if apiCallResult == .failed, let error {
                if case let APIError.apiClientError(clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = error, let clientErrorData, clientErrorData.code == INVALID_VERIFICATION_CODE || clientErrorData.code == UNSUCCESSFUL_VERIFICATION {
                    if let context = clientErrorData.context, let projectId = context["projectId"] {
                        let errorResponse = ActivationTokenErrorResponse(
                            projectId: projectId,
                            userId: userId,
                            accessId: context["accessId"]
                        )

                        callCompletionHandler(
                            with: ActivationTokenError.unsuccessfulVerification(activationTokenErrorResponse: errorResponse)
                        )

                    } else {
                        callCompletionHandler(with: ActivationTokenError.unsuccessfulVerification(activationTokenErrorResponse: nil))
                    }
                } else {
                    callCompletionHandler(with: ActivationTokenError.getActivationTokenFail(error))
                }

                return
            }

            guard let response = response else {
                callCompletionHandler(
                    with: ActivationTokenError.getActivationTokenFail(nil)
                )
                return
            }

            let activationTokenResponse = ActivationTokenResponse(
                activationToken: response.actToken,
                projectId: response.projectId,
                userId: userId, accessId: response.accessId
            )

            DispatchQueue.main.async {
                completionHandler(activationTokenResponse, nil)
            }

            logOperation(operation: LoggingConstants.finished)
        }
    }

    private static func getUserId(components: URLComponents?) -> String? {
        guard let userId =
            components?
                .queryItems?
                .first(where: { item -> Bool in
                    item.name == "user_id"
                })?.value else {
            return nil
        }

        return userId
    }

    private static func getActivationCode(components: URLComponents?) -> String? {
        guard let activationCode =
            components?
                .queryItems?
                .first(where: { item -> Bool in
                    item.name == "code"
                })?.value else {
            return nil
        }

        return activationCode
    }

    func validateInput() throws {
        if userId != nil {
            if userId!.isEmpty {
                throw ActivationTokenError.emptyUserId
            }
        } else {
            throw ActivationTokenError.emptyUserId
        }

        if activationCode != nil {
            if activationCode!.isEmpty {
                throw ActivationTokenError.emptyVerificationCode
            }
        } else {
            throw ActivationTokenError.emptyVerificationCode
        }
    }

    private func callCompletionHandler(with error: Error) {
        DispatchQueue.main.async {
            completionHandler(nil, error)
        }
    }

    private func logOperation(operation: String) {
        miraclLogger.info(
            message: "\(operation)",
            category: .verificationConfirmation
        )
    }
}
