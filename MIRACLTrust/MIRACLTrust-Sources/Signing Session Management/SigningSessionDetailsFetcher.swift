import Foundation

let INVALID_REQUEST_PARAMETERS = "INVALID_REQUEST_PARAMETERS"

struct SigningSessionDetailsFetcher: Sendable {
    let accessId: String
    let miraclAPI: APIBlueprint
    let completionHandler: SigningSessionDetailsCompletionHandler
    let logger: Logger

    init(
        qrCode: String,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        logger: Logger = MIRACLTrust.getInstance().logger,
        completionHandler: @escaping SigningSessionDetailsCompletionHandler
    ) throws {
        self.miraclAPI = miraclAPI
        self.logger = logger
        accessId = try SigningSessionDetailsFetcher.getAccessId(from: qrCode)
        self.completionHandler = completionHandler
    }

    init(
        universalLinkURL: URL,
        miraclAPI: APIBlueprint = MIRACLTrust.getInstance().miraclAPI,
        logger: Logger = MIRACLTrust.getInstance().logger,
        completionHandler: @escaping SigningSessionDetailsCompletionHandler
    ) throws {
        self.miraclAPI = miraclAPI
        self.logger = logger
        accessId = try SigningSessionDetailsFetcher.getAccessId(from: universalLinkURL)
        self.completionHandler = completionHandler
    }

    func fetch() {
        DispatchQueue.main.async {
            fetchSigningSessionDetails()
        }
    }

    private func fetchSigningSessionDetails() {
        miraclAPI.getSigningSessionDetails(
            accessId: accessId,
            completionHandler: { _, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        if case let APIError.apiClientError(statusCode: _, clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = error, let clientErrorData, clientErrorData.code == INVALID_REQUEST_PARAMETERS, let context = clientErrorData.context, context["params"] == "id" {
                            completionHandler(nil, SigningSessionError.invalidSigningSession)
                            return
                        }

                        completionHandler(nil, SigningSessionError.getSigningSessionDetailsFail(error))
                        return
                    }

                    guard let response = response else {
                        completionHandler(nil, SigningSessionError.getSigningSessionDetailsFail(nil))
                        return
                    }

                    let signingSessionDetails = SigningSessionDetails(
                        userId: response.userID,
                        projectName: response.projectName,
                        projectLogoURL: response.projectLogoURL,
                        projectId: response.projectId,
                        pinLength: response.pinLength,
                        verificationMethod: VerificationMethod.verificationMethodFromString(response.verificationMethod),
                        verificationURL: response.verificationURL,
                        verificationCustomText: response.verificationCustomText,
                        identityTypeLabel: response.identityTypeLabel,
                        quickCodeEnabled: response.enableRegistrationCode,
                        identityType: IdentityType.identityTypeFromString(response.identityType),
                        sessionId: accessId,
                        signingHash: response.signingHash,
                        signingDescription: response.signingDescription,
                        status: SigningSessionStatus.signingSessionStatus(from: response.status),
                        expireTime: Date(timeIntervalSince1970: TimeInterval(response.expireTime))
                    )

                    completionHandler(signingSessionDetails, nil)
                }
            }
        )
    }

    private static func getAccessId(
        from qrCode: String
    ) throws -> String {
        if let url = URL(string: qrCode),
           let accessId = url.fragment,
           !accessId.isEmpty {
            return accessId
        }

        throw SigningSessionError.invalidQRCode
    }

    private static func getAccessId(
        from universalLinkURL: URL
    ) throws -> String {
        if let accessId = universalLinkURL.fragment,
           !accessId.isEmpty {
            return accessId
        }

        throw SigningSessionError.invalidUniversalLinkURL
    }
}
