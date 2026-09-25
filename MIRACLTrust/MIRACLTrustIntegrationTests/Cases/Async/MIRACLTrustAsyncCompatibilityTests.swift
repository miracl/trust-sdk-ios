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

    // swiftlint:disable:next function_body_length
    @Test func compatibility() async throws {
        let storage = SQLiteUserStorage(
            projectId: projectIdCUV,
            databaseName: "miracl_async_test_db"
        )

        let pinCode = MIRACLTrustAsyncCompatibilityTests.makeRandomPin()
        let userId = createMailpitUserId()

        let configuration = try Configuration.Builder(
            projectId: projectIdCUV,
            projectURL: projectURLCUV
        )
        .userStorage(userStorage: storage)
        .build()

        try MIRACLTrust.configure(with: configuration)
        let miraclTrust = MIRACLTrust.getInstance()

        let verificationURL = try await platformAPI.getVerificationURL(serviceAccountToken: serviceAccountToken, projectId: projectIdCUV, projectURL: projectURLCUV, userId: userId)
        var activationTokenResponse = try await miraclTrust.getActivationToken(verificationURL: verificationURL)
        var user = try await miraclTrust.register(userId: userId, activationToken: activationTokenResponse.activationToken) { processPinHandler in
            processPinHandler(pinCode)
        }

        let registrationError = await #expect(throws: RegistrationError.self, performing: {
            try await miraclTrust.register(userId: "", activationToken: activationTokenResponse.activationToken) { processPinHandler in
                processPinHandler(pinCode)
            }
        })
        #expect(registrationError == RegistrationError.emptyUserId)

        user = try #require(await miraclTrust.getUsers().first(where: { user in
            user.userId == userId
        }))

        let jwt = try await miraclTrust.authenticate(user: user) { processPinHandler in
            processPinHandler(pinCode)
        }
        let jwksURL = try #require(URL(string: "\(projectURLCUV)/.well-known/jwks"))
        let jwks = try String(contentsOf: jwksURL)
        let signers = JWTSigners()
        try signers.use(jwksJSON: jwks)
        let payload = try signers.verify(jwt, as: AuthenticationJWTPayload.self)
        #expect(payload.sub.value == userId)
        #expect(payload.aud.value.contains(projectIdCUV))

        var authenticationError = await #expect(throws: AuthenticationError.self, performing: {
            try await miraclTrust.authenticate(user: user) { processPinHandler in
                processPinHandler("")
            }
        })
        #expect(authenticationError == AuthenticationError.invalidPin)

        user = try #require(await miraclTrust.getUser(userId: userId))
        let message = try #require(UUID().uuidString.data(using: .utf8))
        let signingResult = try await miraclTrust.sign(message: message, user: user) { processPinHandler in
            processPinHandler(pinCode)
        }
        let signingVerificationResult = try await platformAPI.verifySignatureAsync(signingResult: signingResult, serviceAccountToken: serviceAccountToken, projectId: projectIdCUV, projectURL: projectURLCUV)
        #expect(!signingVerificationResult.certificate.isEmpty)

        var signingError = await #expect(throws: SigningError.self, performing: {
            try await miraclTrust.sign(message: message, user: user) { processPinHandler in
                processPinHandler("")
            }
        })
        #expect(signingError == SigningError.invalidPin)

        let session = try await platformAPI.getAsyncAccessId(projectId: projectIdCUV, projectURL: projectURLCUV, userId: userId, hash: UUID().uuidString)
        let qrCode = "https://mcl.mpin.io#\(session.accessId)"
        var crossDeviceSession = try await miraclTrust.getCrossDeviceSessionFromQRCode(qrCode: qrCode)
        #expect(crossDeviceSession.projectId == projectIdCUV)

        var crossDeviceSessionError = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await miraclTrust.getCrossDeviceSessionFromQRCode(qrCode: "")
        })
        #expect(crossDeviceSessionError == CrossDeviceSessionError.invalidQRCode)

        let dvUniversalLinkURL = try #require(URL(string: qrCode))
        crossDeviceSession = try await miraclTrust.getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL: dvUniversalLinkURL)
        #expect(crossDeviceSession.projectId == projectIdCUV)

        crossDeviceSessionError = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await miraclTrust.getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL: #require(URL(string: "https://example.com")))
        })
        #expect(crossDeviceSessionError == CrossDeviceSessionError.invalidUniversalLinkURL)

        let pushNotificationsPayload = ["userID": userId, "qrURL": qrCode, "projectID": projectURLCUV]
        crossDeviceSession = try await miraclTrust.getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload: pushNotificationsPayload)

        crossDeviceSessionError = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await miraclTrust.getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload: [:])
        })
        #expect(crossDeviceSessionError == CrossDeviceSessionError.invalidPushNotificationPayload)

        try await miraclTrust.authenticateCrossDeviceSession(crossDeviceSession: crossDeviceSession, user: user) { processPinHndler in
            processPinHndler(pinCode)
        }

        authenticationError = await #expect(throws: AuthenticationError.self, performing: {
            try await miraclTrust.authenticateCrossDeviceSession(crossDeviceSession: crossDeviceSession, user: user) { processPinHandler in
                processPinHandler("")
            }
        })
        #expect(authenticationError == AuthenticationError.invalidPin)

        try await miraclTrust.signCrossDeviceSession(crossDeviceSession: crossDeviceSession, user: user) { processPinHandler in
            processPinHandler(pinCode)
        }

        signingError = await #expect(throws: SigningError.self, performing: {
            try await miraclTrust.signCrossDeviceSession(crossDeviceSession: crossDeviceSession, user: user) { processPinHandler in
                processPinHandler("")
            }
        })
        #expect(signingError == SigningError.invalidPin)

        try await miraclTrust.abortCrossDeviceSession(crossDeviceSession: crossDeviceSession)

        let quickCode = try await miraclTrust.generateQuickCode(user: user, didRequestPinHandler: { processPinHandler in
            processPinHandler(pinCode)
        })
        #expect(!quickCode.code.isEmpty)

        let quickCodeError = await #expect(throws: QuickCodeError.self, performing: {
            try await miraclTrust.generateQuickCode(user: user) { processPinHandler in
                processPinHandler("")
            }
        })
        #expect(quickCodeError == QuickCodeError.invalidPin)

        activationTokenResponse = try await miraclTrust.getActivationToken(userId: userId, code: quickCode.code)
        #expect(activationTokenResponse.projectId == projectIdCUV)

        let activationTokenError = await #expect(throws: ActivationTokenError.self, performing: {
            try await miraclTrust.getActivationToken(userId: "", code: quickCode.code)
        })
        #expect(activationTokenError == ActivationTokenError.emptyUserId)

        user = try await miraclTrust.register(userId: userId, activationToken: activationTokenResponse.activationToken, didRequestPinHandler: { processPinHandler in
            processPinHandler(pinCode)
        })
        try await miraclTrust.delete(user: user)

        try miraclTrust.updateProjectSettings(projectId: projectIdDV, projectURL: projectURLDV)

        var verificationResponse = try await miraclTrust.sendVerificationEmail(userId: userId)
        #expect(verificationResponse.method == .link)

        var verificationError = await #expect(throws: VerificationError.self, performing: {
            try await miraclTrust.sendVerificationEmail(userId: "")
        })
        #expect(verificationError == VerificationError.emptyUserId)

        let targetTimestamp = TimeInterval(verificationResponse.backoff)
        let remainingSeconds = targetTimestamp - Date().timeIntervalSince1970
        try await Task.sleep(for: .seconds(remainingSeconds + 1))

        let dvSsession = try await platformAPI.getAsyncAccessId(projectId: projectIdDV, projectURL: projectURLDV, userId: userId)
        let dvQRCode = "https://mcl.mpin.io#\(dvSsession.accessId)"
        let dvCrossDeviceSession = try await miraclTrust.getCrossDeviceSessionFromQRCode(qrCode: dvQRCode)

        verificationResponse = try await miraclTrust.sendVerificationEmail(userId: userId, crossDeviceSession: dvCrossDeviceSession)
        #expect(verificationResponse.method == .link)

        verificationError = await #expect(throws: VerificationError.self, performing: {
            try await miraclTrust.sendVerificationEmail(userId: "", crossDeviceSession: crossDeviceSession)
        })
        #expect(verificationError == VerificationError.emptyUserId)
    }

    private static func makeRandomPin(length: Int = 4) -> String {
        var pinBuilder = ""
        for _ in 0 ..< length {
            pinBuilder.append(String(Int.random(in: 0 ... 9)))
        }

        return pinBuilder
    }
}
