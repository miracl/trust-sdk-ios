import MIRACLTrust
import Testing

struct CrossDeviceSessionAborterIntegrationTest {
    let projectId = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let url = ProcessInfo.processInfo.environment["platformURL"]!

    let crossDeviceSessionCase = CrossDeviceSessionCase()
    let abortCrossDeviceSessionCase = CrossDeviceSessionAbortCase()
    let platformAPI = PlatformAPIWrapper()

    var sessionId: String
    var crossDeviceSession: CrossDeviceSession

    init() async throws {
        let configuration = try Configuration.Builder(
            projectId: projectId
        )
        .platformURL(url: URL(string: url)!)
        .build()

        try MIRACLTrust.configure(with: configuration)

        sessionId = try await platformAPI.getAsyncAccessId(projectId: projectId)
        let qrCode = "https://mcl.mpin.io#\(sessionId)"
        crossDeviceSession = try await crossDeviceSessionCase.getCrossDeviceSessionForQRCode(qrCode: qrCode)
    }

    @Test("Abort Cross device session", .timeLimit(.minutes(1)))
    func abortCrossDeviceSession() async throws {
        let result = try await abortCrossDeviceSessionCase.abortCrossDeviceSession(crossDeviceSession)
        #expect(result == true)
    }

    @Test("Abort cross device session for empty access id", .timeLimit(.minutes(1)))
    func abortCrossDeviceSessionEmptyAccessId() async throws {
        let session = createCrossDeviceSessionObject(sessionId: "")
        let error = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await abortCrossDeviceSessionCase.abortCrossDeviceSession(session)
        })

        #expect(error == CrossDeviceSessionError.invalidCrossDeviceSession)
    }

    // MARK: Private

    private func createCrossDeviceSessionObject(
        sessionId: String = UUID().uuidString
    ) -> CrossDeviceSession {
        CrossDeviceSession(
            userId: UUID().uuidString,
            projectName: UUID().uuidString,
            projectLogoURL: UUID().uuidString,
            projectId: UUID().uuidString,
            pinLength: 4,
            verificationMethod: .standardEmail,
            verificationURL: UUID().uuidString,
            verificationCustomText: UUID().uuidString,
            identityTypeLabel: UUID().uuidString,
            quickCodeEnabled: true,
            limitQuickCodeRegistration: false,
            identityType: .email,
            sessionId: sessionId,
            sessionDescription: "",
            signingHash: ""
        )
    }
}
