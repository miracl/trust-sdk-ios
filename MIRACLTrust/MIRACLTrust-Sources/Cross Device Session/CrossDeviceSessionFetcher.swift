import Foundation

typealias CrossDeviceSessionResultCompletionHandler = @MainActor @Sendable (Result<CrossDeviceSession, Error>) -> Void

final class CrossDeviceSessionFetcher: Sendable {
    let sessionId: String
    let miraclAPI: APIBlueprint
    let completionHandler: CrossDeviceSessionResultCompletionHandler
    let logger: Logger

    init(
        qrCode: String,
        miraclAPI: APIBlueprint,
        logger: Logger,
        completionHandler: @escaping CrossDeviceSessionResultCompletionHandler
    ) throws {
        sessionId = try CrossDeviceSessionFetcher.getAccessIdFromQRCode(qrCode: qrCode)
        self.miraclAPI = miraclAPI
        self.completionHandler = completionHandler
        self.logger = logger
    }

    init(
        universalLinkURL: URL,
        miraclAPI: APIBlueprint,
        logger: Logger,
        completionHandler: @escaping CrossDeviceSessionResultCompletionHandler
    ) throws {
        sessionId = try CrossDeviceSessionFetcher.getAccessId(from: universalLinkURL)
        self.miraclAPI = miraclAPI
        self.completionHandler = completionHandler
        self.logger = logger
    }

    init(
        pushNotificationPayload: [AnyHashable: Any],
        miraclAPI: APIBlueprint,
        logger: Logger,
        completionHandler: @escaping CrossDeviceSessionResultCompletionHandler
    ) throws {
        sessionId = try CrossDeviceSessionFetcher.getAccessId(from: pushNotificationPayload)
        self.miraclAPI = miraclAPI
        self.completionHandler = completionHandler
        self.logger = logger
    }

    func fetch() {
        DispatchQueue.global().async {
            self.fetchCrossDeviceSession()
        }
    }

    func fetchCrossDeviceSession() {
        miraclAPI.getCrossDeviceSession(sessionId: sessionId) { _, response, error in
            if let error {
                self.callCompletionHandler(with: CrossDeviceSessionError.getCrossDeviceSessionFail(error))
                return
            }

            guard let response else {
                self.callCompletionHandler(with: CrossDeviceSessionError.getCrossDeviceSessionFail(nil))
                return
            }

            let crossDeviceSession = CrossDeviceSession(
                userId: response.prerollId,
                projectId: response.projectId,
                sessionId: self.sessionId,
                sessionDescription: response.sessionDescription,
                signingHash: response.signingHash
            )

            DispatchQueue.main.async {
                self.completionHandler(.success(crossDeviceSession))
            }
        }
    }

    // MARK: Private

    private func callCompletionHandler(with error: Error) {
        DispatchQueue.main.async {
            self.completionHandler(.failure(error))
        }
    }

    private static func getAccessIdFromQRCode(
        qrCode: String
    ) throws -> String {
        if let url = URL(string: qrCode),
           let accessId = url.fragment,
           !accessId.isEmpty {
            return accessId
        }

        throw CrossDeviceSessionError.invalidQRCode
    }

    private static func getAccessId(
        from universalLinkURL: URL
    ) throws -> String {
        if let accessId = universalLinkURL.fragment,
           !accessId.isEmpty {
            return accessId
        }

        throw CrossDeviceSessionError.invalidUniversalLinkURL
    }

    private static func getAccessId(
        from pushNotificationsPayload: [AnyHashable: Any]
    ) throws -> String {
        if let qrCode = pushNotificationsPayload["qrURL"] as? String,
           let url = URL(string: qrCode),
           let accessId = url.fragment, !accessId.isEmpty {
            return accessId
        }

        throw CrossDeviceSessionError.invalidPushNotificationPayload
    }
}
