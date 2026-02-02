import Foundation

let BACKOFF_ERROR = "BACKOFF_ERROR"
let REQUEST_BACKOFF = "REQUEST_BACKOFF"

struct Verificator: Sendable {
    let userId: String
    let projectId: String
    let deviceName: String
    let sessionIdentifier: String?
    let completionHandler: VerificationCompletionHandler
    let miraclAPI: APIBlueprint
    let userStorage: UserStorage
    let logger: Logger

    init(userId: String,
         projectId: String,
         deviceName: String,
         sessionIdentifier: String?,
         miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
         userStorage: UserStorage = MIRACLTrust.getInstance().userStorage,
         logger: Logger = MIRACLTrust.getInstance().logger,
         completionHandler: @escaping VerificationCompletionHandler) throws {
        self.userId = userId
        self.projectId = projectId
        self.sessionIdentifier = sessionIdentifier
        self.deviceName =
            deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.miraclAPI = miraclAPI
        self.userStorage = userStorage
        self.logger = logger
        self.completionHandler = completionHandler

        try validateInput()
    }

    func verify() {
        logOperation(operation: LoggingConstants.started)

        DispatchQueue.global(qos: .default).async {
            logOperation(operation: LoggingConstants.verificationStarted)

            let userDTO = try? userStorage.getUser(by: userId, projectId: projectId)

            let mpinId = userDTO?.mpinId.hex

            miraclAPI.verifyUser(
                projectId: projectId,
                userId: userId,
                deviceName: deviceName,
                accessId: sessionIdentifier,
                mpinId: mpinId
            ) { _, verificationAPIResponse, error in
                logOperation(operation: LoggingConstants.finished)

                DispatchQueue.main.async {
                    if let verificationAPIResponse {
                        let verificationResponse = VerificationResponse(
                            backoff: verificationAPIResponse.backoff,
                            method: EmailVerificationMethod.emailVerificationMethodFromString(verificationAPIResponse.method)
                        )
                        completionHandler(verificationResponse, nil)
                    } else if let error {
                        if case let APIError.apiClientError(statusCode: _, clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = error,
                           let clientErrorData,
                           clientErrorData.code == BACKOFF_ERROR || clientErrorData.code == REQUEST_BACKOFF,
                           let context = clientErrorData.context,
                           let backoffString = context["backoff"],
                           let backoff = Int64(backoffString) {
                            completionHandler(
                                nil,
                                VerificationError.requestBackoff(backoff: backoff)
                            )

                            return
                        }

                        completionHandler(nil, VerificationError.verificaitonFail(error))
                    } else {
                        completionHandler(nil, VerificationError.verificaitonFail(nil))
                    }
                }
            }
        }
    }

    private func validateInput() throws {
        if let sessionIdentifier, sessionIdentifier.isEmpty {
            throw VerificationError.invalidSessionDetails
        }

        if userId.isEmpty {
            throw VerificationError.emptyUserId
        }
    }

    private func logOperation(operation: String) {
        logger.info(
            message: "\(operation)",
            category: .verification
        )
    }
}
