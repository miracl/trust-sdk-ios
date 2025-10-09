import Foundation

struct AuthenticationSessionDetailsFetcher: Sendable {
    let accessId: String
    let miraclAPI: APIBlueprint
    let completionHandler: AuthenticationSessionDetailsCompletionHandler
    let logger: Logger

    init(
        qrCode: String,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        logger: Logger = MIRACLTrust.getInstance().logger,
        completionHandler: @escaping AuthenticationSessionDetailsCompletionHandler
    ) throws {
        accessId = try AuthenticationSessionDetailsFetcher.getAccessId(from: qrCode)
        self.logger = logger
        self.miraclAPI = miraclAPI
        self.completionHandler = completionHandler
    }

    init(
        universalLinkURL: URL,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        logger: Logger = MIRACLTrust.getInstance().logger,
        completionHandler: @escaping AuthenticationSessionDetailsCompletionHandler
    ) throws {
        accessId = try AuthenticationSessionDetailsFetcher.getAccessId(from: universalLinkURL)
        self.logger = logger
        self.miraclAPI = miraclAPI
        self.completionHandler = completionHandler
    }

    init(
        pushNotificationsPayload: [AnyHashable: Any],
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        logger: Logger = MIRACLTrust.getInstance().logger,
        completionHandler: @escaping AuthenticationSessionDetailsCompletionHandler
    ) throws {
        accessId = try AuthenticationSessionDetailsFetcher.getAccessId(from: pushNotificationsPayload)
        self.logger = logger
        self.miraclAPI = miraclAPI
        self.completionHandler = completionHandler
    }

    func fetch() {
        logger.info(
            message: LoggingConstants.started,
            category: .sessionManagement
        )

        logger.info(
            message: LoggingConstants.fetchSessionDetailsRequest,
            category: .sessionManagement
        )

        miraclAPI.getSessionDetails(
            accessId: accessId
        ) { _, sessionDetailsResponse, error in
            DispatchQueue.main.async {
                if let sessionDetailsResponse = sessionDetailsResponse {
                    let sessionDetails = AuthenticationSessionDetails(
                        userId: sessionDetailsResponse.prerollId,
                        projectName: sessionDetailsResponse.projectName,
                        projectLogoURL: sessionDetailsResponse.projectLogoURL,
                        projectId: sessionDetailsResponse.projectId,
                        pinLength: sessionDetailsResponse.pinLength,
                        verificationMethod: VerificationMethod.verificationMethodFromString(sessionDetailsResponse.verificationMethod),
                        verificationURL: sessionDetailsResponse.verificationURL,
                        verificationCustomText: sessionDetailsResponse.verificationCustomText,
                        identityTypeLabel: sessionDetailsResponse.identityTypeLabel,
                        quickCodeEnabled: sessionDetailsResponse.quickCodeEnabled,
                        identityType: IdentityType.identityTypeFromString(sessionDetailsResponse.identityType),
                        accessId: accessId
                    )

                    logger.info(
                        message: LoggingConstants.finished,
                        category: .sessionManagement
                    )

                    completionHandler(sessionDetails, nil)
                } else if let error = error {
                    logger.info(
                        message: "\(LoggingConstants.finishedWithError) = \(error)",
                        category: .sessionManagement
                    )
                    completionHandler(nil, AuthenticationSessionError.getAuthenticationSessionDetailsFail(error))
                } else {
                    logger.info(
                        message: "\(LoggingConstants.finishedWithError) = \(AuthenticationSessionError.getAuthenticationSessionDetailsFail(nil))",
                        category: .sessionManagement
                    )
                    completionHandler(nil, AuthenticationSessionError.getAuthenticationSessionDetailsFail(nil))
                }
            }
        }
    }

    // MARK: Private

    private static func getAccessId(
        from qrCode: String
    ) throws -> String {
        if let url = URL(string: qrCode),
           let accessId = url.fragment,
           !accessId.isEmpty {
            return accessId
        }

        throw AuthenticationSessionError.invalidQRCode
    }

    private static func getAccessId(
        from universalLinkURL: URL
    ) throws -> String {
        if let accessId = universalLinkURL.fragment,
           !accessId.isEmpty {
            return accessId
        }

        throw AuthenticationSessionError.invalidUniversalLinkURL
    }

    private static func getAccessId(
        from pushNotificationsPayload: [AnyHashable: Any]
    ) throws -> String {
        if let qrCode = pushNotificationsPayload["qrURL"] as? String,
           let url = URL(string: qrCode),
           let accessId = url.fragment, !accessId.isEmpty {
            return accessId
        }

        throw AuthenticationSessionError.invalidPushNotificationPayload
    }
}
