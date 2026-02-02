import MIRACLTrust
import Testing

struct CrossDeviceSessionAuthenticationIntegrationTest {
    let projectId = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let serviceAccountToken = ProcessInfo.processInfo.environment["serviceAccountTokenCUV"]!
    let projectURL = ProcessInfo.processInfo.environment["projectURLCUV"]!
    let userId = "int@miracl.com"

    let activationTokenCase = ActivationTokenAsyncCase()
    let crossDeviceSessionCase = CrossDeviceSessionCase()
    let platformAPI = PlatformAPIWrapper()

    var registrationCase = RegistrationAsyncTestCase()
    var authenticationTestCase = CrossDeviceSessionAuthenticationCase()

    var randomPIN = ""
    var user: User
    var crossDeviceSession: CrossDeviceSession
    var session: StartSessionResult

    init() async throws {
        randomPIN = CrossDeviceSessionAuthenticationIntegrationTest.makeRandomPin()
        registrationCase.pinCode = randomPIN
        authenticationTestCase.pinCode = randomPIN

        let configuration = try Configuration.Builder(
            projectId: projectId,
            projectURL: projectURL
        ).build()

        try MIRACLTrust.configure(with: configuration)

        session = try await platformAPI.getAsyncAccessId(projectId: projectId, projectURL: projectURL)
        let qrCode = "https://mcl.mpin.io#\(session.accessId)"
        crossDeviceSession = try await crossDeviceSessionCase.getCrossDeviceSessionForQRCode(qrCode: qrCode)
        let activationToken = try await activationTokenCase.getActivationToken(
            serviceAccountToken: serviceAccountToken,
            projectId: projectId,
            projectURL: projectURL,
            userId: userId
        )
        user = try await registrationCase.register(userId: userId, activationToken: activationToken)
    }

    @Test("Tests successful authentication with cross device session for QR Code", .timeLimit(.minutes(1)))
    func authenticationWithQRCodeCrossDeviceSession() async throws {
        let isAuthenticated = try await authenticationTestCase.authenticate(
            user: user,
            crossDeviceSession: crossDeviceSession
        )
        #expect(isAuthenticated)
    }

    @Test("Tests successful authentication with cross device session for Universal Link URL", .timeLimit(.minutes(1)))
    func authenticationWithUniviversalLinkURLCrossDeviceSession() async throws {
        let url = try #require(URL(string: "https://mcl.mpin.io/#\(session.accessId)"))
        let crossDeviceSession = try await crossDeviceSessionCase
            .getCrossDeviceSessionForUniversalLinkURL(universalLinkURL: url)
        let isAuthenticated = try await authenticationTestCase.authenticate(
            user: user,
            crossDeviceSession: crossDeviceSession
        )

        #expect(isAuthenticated)
    }

    @Test("Tests successful authentication with cross device session for Universal Link URL", .timeLimit(.minutes(1)))
    func authenticationWithPushNotificationPayloadForCrossDeviceSession() async throws {
        let qrCode = "https://mcl.mpin.io#\(session.accessId)"
        let payload = [
            "qrURL": qrCode
        ]
        let crossDeviceSession = try await crossDeviceSessionCase
            .getCrossDeviceSessionForPushNotificationPayload(payload: payload)
        let isAuthenticated = try await authenticationTestCase.authenticate(
            user: user,
            crossDeviceSession: crossDeviceSession
        )

        #expect(isAuthenticated)
    }

    @Test("Tests failed authentication with invalid session id", .timeLimit(.minutes(1)))
    func authenticationFailedWithWrongSessionId() async {
        let crossDeviceSession = createCrossDeviceSessionObject()

        let desiredError = AuthenticationError.invalidCrossDeviceSession
        let error = await #expect(throws: AuthenticationError.self, performing: {
            try await authenticationTestCase.authenticate(
                user: user,
                crossDeviceSession: crossDeviceSession
            )
        })

        #expect(desiredError == error)
    }

    @Test("Tests failed authentication with empty session id", .timeLimit(.minutes(1)))
    func authenticationFailedWithEmptySessionId() async throws {
        let crossDeviceSession = createCrossDeviceSessionObject(sessionId: "")

        let error = await #expect(throws: AuthenticationError.self) {
            try await authenticationTestCase.authenticate(
                user: user,
                crossDeviceSession: crossDeviceSession
            )
        }

        var isAuthenticationFailError = false
        if let error, case .authenticationFail = error {
            isAuthenticationFailError = true
        }
        #expect(isAuthenticationFailError)
    }

    @Test("Tests failed authentication for invalid pin (e.g `abcde`)", .timeLimit(.minutes(1)))
    mutating func failedAuthenticationWithInvalidPin() async {
        authenticationTestCase.pinCode = UUID().uuidString

        let desiredError = AuthenticationError.invalidPin
        let error = await #expect(throws: AuthenticationError.self, performing: {
            try await authenticationTestCase.authenticate(
                user: user,
                crossDeviceSession: crossDeviceSession
            )
        })

        #expect(desiredError == error)
    }

    @Test("Tests failed authentication for wrong pin", .timeLimit(.minutes(1)))
    mutating func failedAuthenticationWithWrongPin() async {
        authenticationTestCase.pinCode = CrossDeviceSessionAuthenticationIntegrationTest.makeRandomPin()

        let desiredError = AuthenticationError.unsuccessfulAuthentication
        let error = await #expect(throws: AuthenticationError.self, performing: {
            try await authenticationTestCase.authenticate(
                user: user,
                crossDeviceSession: crossDeviceSession
            )
        })

        #expect(desiredError == error)
    }

    @Test("Tests failed authentication for longer pin. 6 instead of 4", .timeLimit(.minutes(1)))
    mutating func failedAuthenticationWithLongerPin() async {
        authenticationTestCase.pinCode = CrossDeviceSessionAuthenticationIntegrationTest.makeRandomPin(length: 6)

        let desiredError = AuthenticationError.invalidPin
        let error = await #expect(throws: AuthenticationError.self, performing: {
            try await authenticationTestCase.authenticate(
                user: user,
                crossDeviceSession: crossDeviceSession
            )
        })

        #expect(desiredError == error)
    }

    @Test("Tests failed authentication for longer pin. 3 instead of 4", .timeLimit(.minutes(1)))
    mutating func failedAuthenticationWithShorterPin() async {
        authenticationTestCase.pinCode = CrossDeviceSessionAuthenticationIntegrationTest.makeRandomPin(length: 3)

        let desiredError = AuthenticationError.invalidPin
        let error = await #expect(throws: AuthenticationError.self, performing: {
            try await authenticationTestCase.authenticate(
                user: user,
                crossDeviceSession: crossDeviceSession
            )
        })

        #expect(desiredError == error)
    }

    @Test("Tests failed authentication for nil pin.", .timeLimit(.minutes(1)))
    mutating func failedAuthenticationWithNilPin() async {
        authenticationTestCase.pinCode = nil

        let desiredError = AuthenticationError.pinCancelled
        let error = await #expect(throws: AuthenticationError.self, performing: {
            try await authenticationTestCase.authenticate(
                user: user,
                crossDeviceSession: crossDeviceSession
            )
        })

        #expect(desiredError == error)
    }

    // MARK: Private

    private static func makeRandomPin(length: Int = 4) -> String {
        var pinBuilder = ""
        for _ in 0 ..< length {
            pinBuilder.append(String(Int.random(in: 0 ... 9)))
        }

        return pinBuilder
    }

    func createCrossDeviceSessionObject(
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
