import Foundation

struct AuthenticationSessionAborter: Sendable {
    let accessId: String
    let miraclAPI: APIBlueprint
    let completionHandler: AuthenticationSessionAborterCompletionHandler
    let miraclLogger: MIRACLLogger

    init(
        accessId: String,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        miraclLogger: MIRACLLogger = MIRACLTrust.getInstance().miraclLogger,
        completionHandler: @escaping AuthenticationSessionAborterCompletionHandler
    ) throws {
        self.accessId = accessId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.miraclAPI = miraclAPI
        self.miraclLogger = miraclLogger
        self.completionHandler = completionHandler

        try validateInput()
    }

    func abort() {
        miraclLogger.info(
            message: LoggingConstants.started,
            category: .sessionManagement
        )

        miraclLogger.info(
            message: LoggingConstants.abortingSessionRequest,
            category: .sessionManagement
        )

        miraclAPI.abortSession(
            accessId: accessId
        ) { result, _, error in
            DispatchQueue.main.async {
                if result == .success {
                    miraclLogger.info(
                        message: LoggingConstants.finished,
                        category: .sessionManagement
                    )
                    completionHandler(true, nil)
                } else if let error = error {
                    miraclLogger.info(
                        message: "\(LoggingConstants.finishedWithError) = \(error)",
                        category: .sessionManagement
                    )
                    completionHandler(false, AuthenticationSessionError.abortSessionFail(error))
                } else {
                    miraclLogger.info(
                        message: "\(LoggingConstants.finishedWithError) = \(AuthenticationSessionError.abortSessionFail(nil))",
                        category: .sessionManagement
                    )
                    completionHandler(
                        false,
                        AuthenticationSessionError.abortSessionFail(nil)
                    )
                }
            }
        }
    }

    private func validateInput() throws {
        if accessId.isEmpty {
            throw AuthenticationSessionError.invalidAuthenticationSessionDetails
        }
    }
}
