import MIRACLTrust
import Testing

struct CrossDeviceSessionIntegrationTest {
    let projectId = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let clientId = ProcessInfo.processInfo.environment["clientIdCUV"]!
    let url = ProcessInfo.processInfo.environment["projectURLCUV"]!
    let expectedProjectId = ProcessInfo.processInfo.environment["projectIdDV"]!

    var hash = UUID().uuidString
    var description = UUID().uuidString
    var sessionId: String

    let crossDeviceSessionCase = CrossDeviceSessionCase()
    let platformAPI = PlatformAPIWrapper()

    init() async throws {
        let configuration = try Configuration.Builder(
            projectId: projectId,
            projectURL: url
        )
        .build()

        sessionId = try await platformAPI.getAsyncAccessId(projectId: projectId, projectURL: url).accessId

        try MIRACLTrust.configure(with: configuration)
    }

    @Test("Get cross device session from QR Code", .timeLimit(.minutes(1)))
    func getCrossDeviceSessionsQRCode() async throws {
        let qrCode = "https://mcl.mpin.io#\(sessionId)"
        let session = try await crossDeviceSessionCase.getCrossDeviceSessionForQRCode(qrCode: qrCode)
        #expect(session.projectId == projectId)
    }

    @Test("Get cross device session for different project and for hash and description", .timeLimit(.minutes(1)))
    func getCrossDeviceSessionForDifferentProject() async throws {
        let hash = UUID().uuidString
        let description = UUID().uuidString
        let sessionId = try await platformAPI.getAsyncAccessId(projectId: expectedProjectId, projectURL: url, hash: hash, description: description).accessId
        let qrCode = "https://mcl.mpin.io#\(sessionId)"
        let session = try await crossDeviceSessionCase.getCrossDeviceSessionForQRCode(qrCode: qrCode)
        #expect(session.projectId == expectedProjectId)
        #expect(session.signingHash == hash)
        #expect(session.sessionDescription == description)
    }

    @Test("Get cross device session for invalid QR Code", .timeLimit(.minutes(1)))
    func getCrossDeviceSessionForInvalidQRCode() async throws {
        let qrCode = "https://mcl.mpin.io#InvalidAccessId"
        let error = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await crossDeviceSessionCase.getCrossDeviceSessionForQRCode(qrCode: qrCode)
        })

        var isJsonError = false

        if case let .getCrossDeviceSessionFail(cause) = error {
            if let cause, case .apiMalformedJSON = cause as? APIError {
                isJsonError = true
            }
        }
        #expect(isJsonError)
    }

    @Test("Get cross device session for empty QR Code", .timeLimit(.minutes(1)))
    func getCrossDeviceSessionForEmptyQRCode() async throws {
        let qrCode = ""
        let error = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await crossDeviceSessionCase.getCrossDeviceSessionForQRCode(qrCode: qrCode)
        })

        #expect(error == CrossDeviceSessionError.invalidQRCode)
    }

    // MARK: Get Session details from universal link URL

    @Test("Get cross device session from Universal Link URL", .timeLimit(.minutes(1)))
    func getCrossDeviceSessionsUniversalLinkURL() async throws {
        let universalLinkURL = try #require(URL(string: "https://mcl.mpin.io#\(sessionId)"))
        let session = try await crossDeviceSessionCase.getCrossDeviceSessionForUniversalLinkURL(universalLinkURL: universalLinkURL)

        #expect(session.projectId == projectId)
    }

    @Test("Get cross device session from Universal Link URL for different project and for hash and description", .timeLimit(.minutes(1)))
    func getCrossDeviceSessionsUniversalLinkURLForDifferentProject() async throws {
        let hash = UUID().uuidString
        let description = UUID().uuidString
        let sessionId = try await platformAPI.getAsyncAccessId(projectId: expectedProjectId, projectURL: url, hash: hash, description: description).accessId
        let universalLinkURL = try #require(URL(string: "https://mcl.mpin.io#\(sessionId)"))
        let session = try await crossDeviceSessionCase.getCrossDeviceSessionForUniversalLinkURL(universalLinkURL: universalLinkURL)

        #expect(session.projectId == expectedProjectId)
        #expect(session.signingHash == hash)
        #expect(session.sessionDescription == description)
    }

    @Test("Get cross device session from Universal Link URL for missing URL fragment", .timeLimit(.minutes(1)))
    func getCrossDeviceSessionsForMissingURLFragment() async throws {
        let universalLinkURL = try #require(URL(string: "https://mcl.mpin.io"))
        let error = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await crossDeviceSessionCase.getCrossDeviceSessionForUniversalLinkURL(universalLinkURL: universalLinkURL)
        })

        #expect(error == CrossDeviceSessionError.invalidUniversalLinkURL)
    }

    // MARK: Get Session details from push notifications payload

    @Test("Get cross device session from push notification payload", .timeLimit(.minutes(1)))
    func getCrossDeviceSessionsFromPushNotificationsPayload() async throws {
        let qrCode = "https://mcl.mpin.io#\(sessionId)"
        let payload = [
            "qrURL": qrCode
        ]

        let session = try await crossDeviceSessionCase.getCrossDeviceSessionForPushNotificationPayload(
            payload: payload
        )
        #expect(session.projectId == projectId)
    }

    @Test("Get cross device session from push notification payload for different projectId", .timeLimit(.minutes(1)))
    func getCrossDeviceSessionsFromPushNotificationsPayloadDifferent() async throws {
        let hash = UUID().uuidString
        let description = UUID().uuidString
        let sessionId = try await platformAPI.getAsyncAccessId(projectId: expectedProjectId, projectURL: url, hash: hash, description: description).accessId
        let qrCode = "https://mcl.mpin.io#\(sessionId)"
        let payload = [
            "qrURL": qrCode
        ]

        let session = try await crossDeviceSessionCase.getCrossDeviceSessionForPushNotificationPayload(payload: payload)

        #expect(session.projectId == expectedProjectId)
        #expect(session.signingHash == hash)
        #expect(session.sessionDescription == description)
    }

    @Test("Get cross device session from push notification payload but missing required entry", .timeLimit(.minutes(1)))
    func getCrossDeviceSessionsFromPushNotificationsPayloadMissingPayloadEntry() async throws {
        let payload = [AnyHashable: Any]()
        let error = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await crossDeviceSessionCase.getCrossDeviceSessionForPushNotificationPayload(payload: payload)
        })

        #expect(error == CrossDeviceSessionError.invalidPushNotificationPayload)
    }

    @Test("Get cross device session from push notifications payload but invalid URL", .timeLimit(.minutes(1)))
    func getCrossDeviceSessionsFromPushNotificationsPayloadInvalidURL() async throws {
        let payload = [
            "qrURL": "InvalidURL"
        ]

        let error = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await crossDeviceSessionCase.getCrossDeviceSessionForPushNotificationPayload(payload: payload)
        })

        #expect(error == CrossDeviceSessionError.invalidPushNotificationPayload)
    }

    @Test("Get cross device session from push notifications payload but invalid URL fragment", .timeLimit(.minutes(1)))
    func getCrossDeviceSessionsFromPushNotificationsPayloadInvalidURLFragment() async throws {
        let payload = [
            "qrURL": "https://mcl.mpin.io#"
        ]

        let error = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await crossDeviceSessionCase.getCrossDeviceSessionForPushNotificationPayload(payload: payload)
        })

        #expect(error == CrossDeviceSessionError.invalidPushNotificationPayload)
    }
}
