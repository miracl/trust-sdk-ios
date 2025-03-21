import Foundation

struct SigningSessionAborter: Sendable {
    let sessionId: String
    let miraclAPI: APIBlueprint
    let completionHandler: SigningSessionAborterCompletionHandler

    init(
        sessionId: String,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        completionHandler: @escaping SigningSessionAborterCompletionHandler
    ) throws {
        self.sessionId = sessionId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.miraclAPI = miraclAPI
        self.completionHandler = completionHandler

        try validateInput()
    }

    func abort() {
        miraclAPI.abortSigningSession(sessionId: sessionId) { _, _, error in
            if let error {
                if case let APIError.apiClientError(clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = error, let clientErrorData, clientErrorData.code == INVALID_REQUEST_PARAMETERS, let context = clientErrorData.context, context["params"] == "id" {
                    callCompletionHandler(
                        isAborted: false,
                        error: SigningSessionError.invalidSigningSession
                    )
                    return
                }

                callCompletionHandler(
                    isAborted: false,
                    error: SigningSessionError.abortSigningSessionFail(error)
                )
                return
            }

            callCompletionHandler(
                isAborted: true,
                error: nil
            )
        }
    }

    // MARK: Private

    private func callCompletionHandler(
        isAborted: Bool,
        error: Error?
    ) {
        DispatchQueue.main.async {
            completionHandler(isAborted, error)
        }
    }

    private func validateInput() throws {
        if sessionId.isEmpty {
            throw SigningSessionError.invalidSigningSessionDetails
        }
    }
}
