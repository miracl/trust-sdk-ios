import Foundation

struct AuthenticationSessionAborter {
    let accessId: String
    let miraclAPI: APIBlueprint
    let completionHandler: AuthenticationSessionAborterCompletionHandler
    let logger: Logger

    init(
        accessId: String,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        logger: Logger = MIRACLTrust.getInstance().logger,
        completionHandler: @escaping AuthenticationSessionAborterCompletionHandler
    ) throws {
        self.accessId = accessId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.miraclAPI = miraclAPI
        self.logger = logger
        self.completionHandler = completionHandler

        try validateInput()
    }

    func abort() {
        logger.info(
            message: LoggingConstants.started,
            category: .sessionManagement
        )

        logger.info(
            message: LoggingConstants.abortingSessionRequest,
            category: .sessionManagement
        )

        miraclAPI.abortSession(
            accessId: accessId
        ) { result, _, error in
            DispatchQueue.main.async {
                if result == .success {
                    logger.info(
                        message: LoggingConstants.finished,
                        category: .sessionManagement
                    )
                    completionHandler(true, nil)
                } else if let error = error {
                    logger.info(
                        message: "\(LoggingConstants.finishedWithError) = \(error)",
                        category: .sessionManagement
                    )
                    completionHandler(false, AuthenticationSessionError.abortSessionFail(error))
                } else {
                    logger.info(
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
