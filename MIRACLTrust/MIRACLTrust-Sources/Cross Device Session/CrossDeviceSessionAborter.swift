import Foundation

typealias CrossDeviceSessionAborterResultCompletionHandler = @MainActor @Sendable (Result<Void, Error>) -> Void

struct CrossDeviceSessionAborter {
    let sessionId: String
    let miraclAPI: APIBlueprint
    let completionHandler: CrossDeviceSessionAborterResultCompletionHandler

    init(
        sessionId: String,
        miraclAPI: APIBlueprint,
        completionHandler: @escaping CrossDeviceSessionAborterResultCompletionHandler
    ) throws {
        self.sessionId = sessionId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.miraclAPI = miraclAPI
        self.completionHandler = completionHandler

        try validateInput()
    }

    func abort() {
        miraclAPI.abortSession(accessId: sessionId) { result, _, error in
            if let error {
                if case let APIError.apiClientError(statusCode: _, clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = error, let clientErrorData, clientErrorData.code == INVALID_REQUEST_PARAMETERS, let context = clientErrorData.context, context["params"] == "id" {
                    callCompletionHandler(
                        error: CrossDeviceSessionError.invalidCrossDeviceSession
                    )
                    return
                }

                callCompletionHandler(
                    error: CrossDeviceSessionError.abortCrossDeviceSessionFail(error)
                )
                return
            }

            if result == .failed {
                callCompletionHandler(
                    error: CrossDeviceSessionError.abortCrossDeviceSessionFail(error)
                )
                return
            }

            DispatchQueue.main.async {
                completionHandler(.success(()))
            }
        }
    }

    // MARK: Private

    private func callCompletionHandler(
        error: Error
    ) {
        DispatchQueue.main.async {
            completionHandler(.failure(error))
        }
    }

    private func validateInput() throws {
        if sessionId.isEmpty {
            throw CrossDeviceSessionError.invalidCrossDeviceSession
        }
    }
}
