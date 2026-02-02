import MIRACLTrust
import Testing

struct CrossDeviceSessionAborterIntegrationTest {
    let projectId = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let projectURL = ProcessInfo.processInfo.environment["projectURLCUV"]!

    let crossDeviceSessionCase = CrossDeviceSessionCase()
    let abortCrossDeviceSessionCase = CrossDeviceSessionAbortCase()
    let platformAPI = PlatformAPIWrapper()

    var session: StartSessionResult
    var crossDeviceSession: CrossDeviceSession

    init() async throws {
        let configuration = try Configuration.Builder(
            projectId: projectId, projectURL: projectURL
        ).build()

        try MIRACLTrust.configure(with: configuration)

        session = try await platformAPI.getAsyncAccessId(
            projectId: projectId,
            projectURL: projectURL
        )
        let qrCode = "https://mcl.mpin.io#\(session.accessId)"
        crossDeviceSession = try await crossDeviceSessionCase.getCrossDeviceSessionForQRCode(qrCode: qrCode)
    }

    @Test("Abort Cross device session", .timeLimit(.minutes(1)))
    func abortCrossDeviceSession() async throws {
        let result = try await abortCrossDeviceSessionCase.abortCrossDeviceSession(crossDeviceSession)
        #expect(result == true)
    }

    @Test("Abort cross device session for empty access id", .timeLimit(.minutes(1)))
    func abortCrossDeviceSessionEmptyAccessId() async {
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
            identityType: .email,
            sessionId: sessionId,
            sessionDescription: "",
            signingHash: ""
        )
    }
}
