import JWTKit
@testable import MIRACLTrust
import Testing

@Suite(.serialized)
struct MIRACLTrustAsyncCompatibilityTests {
    let projectIdCUV = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let projectURLCUV = ProcessInfo.processInfo.environment["projectURLCUV"]!
    let serviceAccountToken = ProcessInfo.processInfo.environment["serviceAccountTokenCUV"]!

    let projectIdDV = ProcessInfo.processInfo.environment["projectIdDV"]!
    let projectURLDV = ProcessInfo.processInfo.environment["projectURLDV"]!

    let platformAPI = PlatformAPIWrapper()

    // MARK: - Registration Tests

    @Test func registrationWithVerificationURL() async throws {
        let miraclTrust = try setupSDK()
        let userId = createMailpitUserId()
        let pinCode = Self.makeRandomPin()

        let verificationURL = try await platformAPI.getVerificationURL(
            serviceAccountToken: serviceAccountToken,
            projectId: projectIdCUV,
            projectURL: projectURLCUV,
            userId: userId
        )
        let activationTokenResponse = try await miraclTrust.getActivationToken(verificationURL: verificationURL)
        let user = try await miraclTrust.register(userId: userId, activationToken: activationTokenResponse.activationToken) { processPinHandler in
            processPinHandler(pinCode)
        }

        #expect(user.userId == userId)
    }

    @Test func getActivationTokenWithInvalidVerificationURLThrowsError() async throws {
        let miraclTrust = try setupSDK()
        let invalidURL = try #require(URL(string: "https://example.com"))

        let activationTokenError = await #expect(throws: ActivationTokenError.self, performing: {
            try await miraclTrust.getActivationToken(verificationURL: invalidURL)
        })
        #expect(activationTokenError == ActivationTokenError.emptyUserId)
    }

    @Test func registrationWithEmptyUserIdThrowsError() async throws {
        let miraclTrust = try setupSDK()
        let userId = createMailpitUserId()

        let verificationURL = try await platformAPI.getVerificationURL(
            serviceAccountToken: serviceAccountToken,
            projectId: projectIdCUV,
            projectURL: projectURLCUV,
            userId: userId
        )
        let activationTokenResponse = try await miraclTrust.getActivationToken(verificationURL: verificationURL)

        let registrationError = await #expect(throws: RegistrationError.self, performing: {
            try await miraclTrust.register(userId: "", activationToken: activationTokenResponse.activationToken) { processPinHandler in
                processPinHandler("1234")
            }
        })
        #expect(registrationError == RegistrationError.emptyUserId)
    }

    // MARK: - Authentication Tests

    @Test func authentication() async throws {
        let (miraclTrust, _, pinCode, userId) = try await registerTestUser()

        let retrievedUser = try #require(await miraclTrust.getUsers().first(where: { $0.userId == userId }))

        let jwt = try await miraclTrust.authenticate(user: retrievedUser) { processPinHandler in
            processPinHandler(pinCode)
        }
        let jwksURL = try #require(URL(string: "\(projectURLCUV)/.well-known/jwks"))
        let jwks = try String(contentsOf: jwksURL)
        let signers = JWTSigners()
        try signers.use(jwksJSON: jwks)
        let payload = try signers.verify(jwt, as: AuthenticationJWTPayload.self)
        #expect(payload.sub.value == userId)
        #expect(payload.aud.value.contains(projectIdCUV))
    }

    @Test func authenticateWithInvalidPinThrowsError() async throws {
        let (miraclTrust, user, _, _) = try await registerTestUser()

        let authenticationError = await #expect(throws: AuthenticationError.self, performing: {
            try await miraclTrust.authenticate(user: user) { processPinHandler in
                processPinHandler("")
            }
        })
        #expect(authenticationError == AuthenticationError.invalidPin)
    }

    // MARK: - Signing Tests

    @Test func signing() async throws {
        let (miraclTrust, user, pinCode, _) = try await registerTestUser()
        let fetchedUser = try #require(await miraclTrust.getUser(userId: user.userId))

        let message = try #require(UUID().uuidString.data(using: .utf8))
        let signingResult = try await miraclTrust.sign(message: message, user: fetchedUser) { processPinHandler in
            processPinHandler(pinCode)
        }
        let signingVerificationResult = try await platformAPI.verifySignatureAsync(
            signingResult: signingResult,
            serviceAccountToken: serviceAccountToken,
            projectId: projectIdCUV,
            projectURL: projectURLCUV
        )
        #expect(!signingVerificationResult.certificate.isEmpty)
    }

    @Test func signWithInvalidPinThrowsError() async throws {
        let (miraclTrust, user, _, _) = try await registerTestUser()
        let message = try #require(UUID().uuidString.data(using: .utf8))

        let signingError = await #expect(throws: SigningError.self, performing: {
            try await miraclTrust.sign(message: message, user: user) { processPinHandler in
                processPinHandler("")
            }
        })
        #expect(signingError == SigningError.invalidPin)
    }

    // MARK: - Cross-Device Session Parsing Tests

    @Test func getCrossDeviceSessionFromQRCode() async throws {
        let (miraclTrust, qrCode) = try await setupQRCodeSession()

        let crossDeviceSession = try await miraclTrust.getCrossDeviceSessionFromQRCode(qrCode: qrCode)
        #expect(crossDeviceSession.projectId == projectIdCUV)
    }

    @Test func getCrossDeviceSessionFromInvalidQRCodeThrowsError() async throws {
        let miraclTrust = try setupSDK()

        let qrError = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await miraclTrust.getCrossDeviceSessionFromQRCode(qrCode: "")
        })
        #expect(qrError == CrossDeviceSessionError.invalidQRCode)
    }

    @Test func getCrossDeviceSessionFromUniversalLinkURL() async throws {
        let (miraclTrust, qrCode) = try await setupQRCodeSession()
        let universalLinkURL = try #require(URL(string: qrCode))

        let crossDeviceSession = try await miraclTrust.getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL: universalLinkURL)
        #expect(crossDeviceSession.projectId == projectIdCUV)
    }

    @Test func getCrossDeviceSessionFromInvalidUniversalLinkURLThrowsError() async throws {
        let miraclTrust = try setupSDK()
        let invalidURL = try #require(URL(string: "https://example.com"))

        let linkError = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await miraclTrust.getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL: invalidURL)
        })
        #expect(linkError == CrossDeviceSessionError.invalidUniversalLinkURL)
    }

    @Test func getCrossDeviceSessionFromPushNotificationPayload() async throws {
        let (miraclTrust, qrCode, userId) = try await setupQRCodeSessionWithUserId()
        let payload = ["userID": userId, "qrURL": qrCode, "projectID": projectURLCUV]

        let crossDeviceSession = try await miraclTrust.getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload: payload)
        #expect(crossDeviceSession.projectId == projectIdCUV)
    }

    @Test func getCrossDeviceSessionFromInvalidPushNotificationPayloadThrowsError() async throws {
        let miraclTrust = try setupSDK()

        let pushError = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await miraclTrust.getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload: [:])
        })
        #expect(pushError == CrossDeviceSessionError.invalidPushNotificationPayload)
    }

    // MARK: - Cross-Device Session Execution Tests

    @Test func authenticateCrossDeviceSession() async throws {
        let (miraclTrust, user, pinCode, session) = try await setupCrossDeviceSession()

        try await miraclTrust.authenticateCrossDeviceSession(crossDeviceSession: session, user: user) { processPinHandler in
            processPinHandler(pinCode)
        }
    }

    @Test func authenticateCrossDeviceSessionWithInvalidPinThrowsError() async throws {
        let (miraclTrust, user, _, session) = try await setupCrossDeviceSession()

        let authError = await #expect(throws: AuthenticationError.self, performing: {
            try await miraclTrust.authenticateCrossDeviceSession(crossDeviceSession: session, user: user) { processPinHandler in
                processPinHandler("")
            }
        })
        #expect(authError == AuthenticationError.invalidPin)
    }

    @Test func signCrossDeviceSession() async throws {
        let (miraclTrust, user, pinCode, session) = try await setupCrossDeviceSession()

        try await miraclTrust.signCrossDeviceSession(crossDeviceSession: session, user: user) { processPinHandler in
            processPinHandler(pinCode)
        }
    }

    @Test func signCrossDeviceSessionWithInvalidPinThrowsError() async throws {
        let (miraclTrust, user, _, session) = try await setupCrossDeviceSession()

        let signError = await #expect(throws: SigningError.self, performing: {
            try await miraclTrust.signCrossDeviceSession(crossDeviceSession: session, user: user) { processPinHandler in
                processPinHandler("")
            }
        })
        #expect(signError == SigningError.invalidPin)
    }

    @Test func abortCrossDeviceSession() async throws {
        let (miraclTrust, _, _, session) = try await setupCrossDeviceSession()

        try await miraclTrust.abortCrossDeviceSession(crossDeviceSession: session)
    }

    // MARK: - Quick Code Flow Tests

    @Test func generateQuickCodeAndReRegister() async throws {
        let (miraclTrust, user, pinCode, userId) = try await registerTestUser()

        let quickCode = try await miraclTrust.generateQuickCode(user: user) { processPinHandler in
            processPinHandler(pinCode)
        }
        #expect(!quickCode.code.isEmpty)

        let activationTokenResponse = try await miraclTrust.getActivationToken(userId: userId, code: quickCode.code)
        #expect(activationTokenResponse.projectId == projectIdCUV)

        let reRegisteredUser = try await miraclTrust.register(
            userId: userId,
            activationToken: activationTokenResponse.activationToken
        ) { processPinHandler in
            processPinHandler(pinCode)
        }
        #expect(reRegisteredUser.userId == userId)
    }

    @Test func generateQuickCodeWithInvalidPinThrowsError() async throws {
        let (miraclTrust, user, _, _) = try await registerTestUser()

        let qcError = await #expect(throws: QuickCodeError.self, performing: {
            try await miraclTrust.generateQuickCode(user: user) { processPinHandler in
                processPinHandler("")
            }
        })
        #expect(qcError == QuickCodeError.invalidPin)
    }

    @Test func getActivationTokenWithEmptyUserIdThrowsError() async throws {
        let (miraclTrust, user, pinCode, _) = try await registerTestUser()
        let quickCode = try await miraclTrust.generateQuickCode(user: user) { processPinHandler in
            processPinHandler(pinCode)
        }

        let tokenError = await #expect(throws: ActivationTokenError.self, performing: {
            try await miraclTrust.getActivationToken(userId: "", code: quickCode.code)
        })
        #expect(tokenError == ActivationTokenError.emptyUserId)
    }

    // MARK: - User Deletion Tests

    @Test func deleteUser() async throws {
        let (miraclTrust, user, _, userId) = try await registerTestUser()

        try await miraclTrust.delete(user: user)

        let deletedUser = try await miraclTrust.getUser(userId: userId)
        #expect(deletedUser == nil)
    }

    // MARK: - Verification Email Tests

    @Test func sendVerificationEmail() async throws {
        let miraclTrust = try setupSDK()
        let userId = createMailpitUserId()

        try miraclTrust.updateProjectSettings(projectId: projectIdDV, projectURL: projectURLDV)

        let verificationResponse = try await miraclTrust.sendVerificationEmail(userId: userId)
        #expect(verificationResponse.method == .link)
    }

    @Test func sendVerificationEmailWithEmptyUserIdThrowsError() async throws {
        let miraclTrust = try setupSDK()
        try miraclTrust.updateProjectSettings(projectId: projectIdDV, projectURL: projectURLDV)

        let verificationError = await #expect(throws: VerificationError.self, performing: {
            try await miraclTrust.sendVerificationEmail(userId: "")
        })
        #expect(verificationError == VerificationError.emptyUserId)
    }

    @Test func sendVerificationEmailWithCrossDeviceSession() async throws {
        let miraclTrust = try setupSDK()
        let userId = createMailpitUserId()
        try miraclTrust.updateProjectSettings(projectId: projectIdDV, projectURL: projectURLDV)

        let dvSession = try await platformAPI.getAsyncAccessId(projectId: projectIdDV, projectURL: projectURLDV, userId: userId)
        let dvQRCode = "https://mcl.mpin.io#\(dvSession.accessId)"
        let dvCrossDeviceSession = try await miraclTrust.getCrossDeviceSessionFromQRCode(qrCode: dvQRCode)

        let verificationResponse = try await miraclTrust.sendVerificationEmail(userId: userId, crossDeviceSession: dvCrossDeviceSession)
        #expect(verificationResponse.method == .link)
    }

    @Test func sendVerificationEmailWithCrossDeviceSessionAndEmptyUserIdThrowsError() async throws {
        let miraclTrust = try setupSDK()
        let userId = createMailpitUserId()
        try miraclTrust.updateProjectSettings(projectId: projectIdDV, projectURL: projectURLDV)

        let dvSession = try await platformAPI.getAsyncAccessId(projectId: projectIdDV, projectURL: projectURLDV, userId: userId)
        let dvQRCode = "https://mcl.mpin.io#\(dvSession.accessId)"
        let dvCrossDeviceSession = try await miraclTrust.getCrossDeviceSessionFromQRCode(qrCode: dvQRCode)

        let verificationError = await #expect(throws: VerificationError.self, performing: {
            try await miraclTrust.sendVerificationEmail(userId: "", crossDeviceSession: dvCrossDeviceSession)
        })
        #expect(verificationError == VerificationError.emptyUserId)
    }

    // MARK: - Helper Methods

    private func setupSDK(databaseName: String = "miracl_async_test_db") throws -> MIRACLTrust {
        let storage = SQLiteUserStorage(
            projectId: projectIdCUV,
            databaseName: databaseName
        )
        let configuration = try Configuration.Builder(
            projectId: projectIdCUV,
            projectURL: projectURLCUV
        )
        .userStorage(userStorage: storage)
        .build()

        try MIRACLTrust.configure(with: configuration)
        return MIRACLTrust.getInstance()
    }

    private func registerTestUser() async throws -> (miraclTrust: MIRACLTrust, user: User, pinCode: String, userId: String) {
        let miraclTrust = try setupSDK()
        let pinCode = Self.makeRandomPin()
        let userId = createMailpitUserId()

        let verificationURL = try await platformAPI.getVerificationURL(
            serviceAccountToken: serviceAccountToken,
            projectId: projectIdCUV,
            projectURL: projectURLCUV,
            userId: userId
        )
        let activationTokenResponse = try await miraclTrust.getActivationToken(verificationURL: verificationURL)
        let user = try await miraclTrust.register(userId: userId, activationToken: activationTokenResponse.activationToken) { processPinHandler in
            processPinHandler(pinCode)
        }

        return (miraclTrust, user, pinCode, userId)
    }

    private func setupQRCodeSessionWithUserId() async throws -> (miraclTrust: MIRACLTrust, qrCode: String, userId: String) {
        let miraclTrust = try setupSDK()
        let userId = createMailpitUserId()
        let session = try await platformAPI.getAsyncAccessId(
            projectId: projectIdCUV,
            projectURL: projectURLCUV,
            userId: userId,
            hash: UUID().uuidString
        )
        let qrCode = "https://mcl.mpin.io#\(session.accessId)"
        return (miraclTrust, qrCode, userId)
    }

    private func setupQRCodeSession() async throws -> (miraclTrust: MIRACLTrust, qrCode: String) {
        let (miraclTrust, qrCode, _) = try await setupQRCodeSessionWithUserId()
        return (miraclTrust, qrCode)
    }

    private func setupCrossDeviceSession() async throws -> (miraclTrust: MIRACLTrust, user: User, pinCode: String, session: CrossDeviceSession) {
        let (miraclTrust, user, pinCode, userId) = try await registerTestUser()
        let sessionData = try await platformAPI.getAsyncAccessId(
            projectId: projectIdCUV,
            projectURL: projectURLCUV,
            userId: userId,
            hash: UUID().uuidString
        )
        let qrCode = "https://mcl.mpin.io#\(sessionData.accessId)"
        let session = try await miraclTrust.getCrossDeviceSessionFromQRCode(qrCode: qrCode)
        return (miraclTrust, user, pinCode, session)
    }

    private static func makeRandomPin(length: Int = 4) -> String {
        var pinBuilder = ""
        for _ in 0 ..< length {
            pinBuilder.append(String(Int.random(in: 0 ... 9)))
        }
        return pinBuilder
    }
}
