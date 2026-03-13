import Foundation

struct CrossDeviceSessionAborter {
    let sessionId: String
    let miraclAPI: APIBlueprint
    let completionHandler: CrossDeviceSessionAborterCompletionHandler

    init(
        sessionId: String,
        miraclAPI: APIBlueprint,
        completionHandler: @escaping CrossDeviceSessionAborterCompletionHandler
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
                        isAborted: false,
                        error: CrossDeviceSessionError.invalidCrossDeviceSession
                    )
                    return
                }

                callCompletionHandler(
                    isAborted: false,
                    error: CrossDeviceSessionError.abortCrossDeviceSessionFail(error)
                )
                return
            }

            if result == .failed {
                callCompletionHandler(
                    isAborted: false,
                    error: CrossDeviceSessionError.abortCrossDeviceSessionFail(error)
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
            throw CrossDeviceSessionError.invalidCrossDeviceSession
        }
    }
}
