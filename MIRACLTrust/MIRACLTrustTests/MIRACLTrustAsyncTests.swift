@testable import MIRACLTrust
import Testing

@Suite(.serialized)
struct MIRACLTrustAsyncTests {
    let projectId = UUID().uuidString
    let projectURL = "https://example.com"

    let mpinId = "7b22696174223a313631373237323435332c22757365724944223a22676c6f62616c406578616d706c652e636f6d222c22634944223a2236636134636133622d623663342d343262332d386536372d336432653038616532643765222c2273616c74223a226d30756558414b4162566234425756742b5461745a51222c2276223a352c2273636f7065223a5b2261757468225d2c22647461223a5b5d2c227674223a227076227d"
    let dtas = "WyJEVEEgTm9kZSIsIkRUQSBOb2RlIl0="
    let clientToken = Data([1, 2, 3])
    let randomString = UUID().uuidString

    init() async throws {
        let configuration = try Configuration.Builder(projectId: projectId, projectURL: projectURL).build()
        try MIRACLTrust.configure(with: configuration)

        MIRACLTrust.getInstance().crypto = createMockCrypto()
    }

    @Test func sendVerificationEmailCrossDeviceSession() async throws {
        let randomBackoff = Int64.random(in: 0 ... Int64.max)
        let method = "link"

        configureMockAPI { mockAPI in
            mockAPI.verificationResultCall = .success
            mockAPI.verificationError = nil
            mockAPI.verificationResponse = VerificationRequestResponse(backoff: randomBackoff, method: method)
        }

        let crossDeviceSession = CrossDeviceSession(userId: UUID().uuidString, projectId: UUID().uuidString, sessionId: UUID().uuidString, sessionDescription: UUID().uuidString, signingHash: UUID().uuidString)
        let verificationResponse = try await MIRACLTrust.getInstance().sendVerificationEmail(userId: UUID().uuidString, crossDeviceSession: crossDeviceSession)
        #expect(verificationResponse.backoff == randomBackoff)
        #expect(verificationResponse.method == .link)
    }

    @Test func sendVerificationEmailCrossDeviceSessionWithError() async {
        let expectedError = apiClientError(with: "Something wrong")

        configureMockAPI { mockAPI in
            mockAPI.verificationResultCall = .failed
            mockAPI.verificationError = expectedError
            mockAPI.verificationResponse = nil
        }

        let crossDeviceSession = CrossDeviceSession(userId: UUID().uuidString, projectId: UUID().uuidString, sessionId: UUID().uuidString, sessionDescription: UUID().uuidString, signingHash: UUID().uuidString)
        let error = await #expect(throws: VerificationError.self, performing: {
            try await MIRACLTrust.getInstance().sendVerificationEmail(userId: UUID().uuidString, crossDeviceSession: crossDeviceSession)
        })

        #expect(error == VerificationError.verificaitonFail(expectedError))
    }

    @Test func sendVerificationEmailCrossDeviceSessionCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            let crossDeviceSession = CrossDeviceSession(userId: UUID().uuidString, projectId: UUID().uuidString, sessionId: UUID().uuidString, sessionDescription: UUID().uuidString, signingHash: UUID().uuidString)
            return try await MIRACLTrust.getInstance().sendVerificationEmail(userId: UUID().uuidString, crossDeviceSession: crossDeviceSession)
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func testSendVerificationEmail() async throws {
        let randomBackoff = Int64.random(in: 0 ... Int64.max)
        let method = "link"

        configureMockAPI { mockAPI in
            mockAPI.verificationResultCall = .success
            mockAPI.verificationError = nil
            mockAPI.verificationResponse = VerificationRequestResponse(backoff: randomBackoff, method: method)
        }

        let verificationResponse = try await MIRACLTrust.getInstance().sendVerificationEmail(userId: UUID().uuidString)
        #expect(verificationResponse.backoff == randomBackoff)
        #expect(verificationResponse.method == .link)
    }

    @Test func sendVerificationEmailWithError() async {
        let expectedError = apiClientError(with: "Something wrong")

        configureMockAPI { mockAPI in
            mockAPI.verificationResultCall = .failed
            mockAPI.verificationError = expectedError
            mockAPI.verificationResponse = nil
        }

        let error = await #expect(throws: VerificationError.self, performing: {
            try await MIRACLTrust.getInstance().sendVerificationEmail(userId: UUID().uuidString)
        })

        #expect(error == VerificationError.verificaitonFail(expectedError))
    }

    @Test func sendVerificationEmailCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await MIRACLTrust.getInstance().sendVerificationEmail(userId: UUID().uuidString)
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func getActivationTokenVerificationURL() async throws {
        let projectId = UUID().uuidString
        let accessId = UUID().uuidString
        let actToken = UUID().uuidString
        let userId = UUID().uuidString

        let verificationURL = try #require(URL(string: "https://example.com?code=af1cc549573718409de44d8bf2e67a06&user_id=\(userId)"))

        configureMockAPI { mockAPI in
            mockAPI.verificationConfirmationResultCall = .success
            mockAPI.verificationConfirmationError = nil
            mockAPI.verificationConfirmationResponse = VerificationConfirmationResponse(
                projectId: projectId,
                accessId: accessId,
                actToken: actToken
            )
        }

        let activationTokenResponse = try await MIRACLTrust.getInstance().getActivationToken(verificationURL: verificationURL)
        #expect(activationTokenResponse.activationToken == actToken)
        #expect(activationTokenResponse.accessId == accessId)
        #expect(activationTokenResponse.projectId == projectId)
        #expect(activationTokenResponse.userId == userId)
    }

    @Test func getActivationTokenVerificationURLError() async throws {
        let userId = UUID().uuidString
        let verificationURL = try #require(URL(string: "https://example.com?code=af1cc549573718409de44d8bf2e67a06&user_id=\(userId)"))
        let cause = apiClientError(with: "Something is wrong")
        let desiredError = ActivationTokenError.getActivationTokenFail(cause)

        configureMockAPI { mockAPI in
            mockAPI.verificationConfirmationResultCall = .failed
            mockAPI.verificationConfirmationError = cause
            mockAPI.verificationConfirmationResponse = nil
        }

        let error = await #expect(throws: ActivationTokenError.self, performing: {
            try await MIRACLTrust.getInstance().getActivationToken(verificationURL: verificationURL)
        })

        #expect(error == desiredError)
    }

    @Test func getActivationTokenVerificationURLCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            let verificationURL = try #require(URL(string: "https://example.com"))
            return try await MIRACLTrust.getInstance().getActivationToken(verificationURL: verificationURL)
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func getActivationTokenWithCode() async throws {
        let projectId = UUID().uuidString
        let accessId = UUID().uuidString
        let actToken = UUID().uuidString

        let userId = UUID().uuidString
        let code = UUID().uuidString

        configureMockAPI { mockAPI in
            mockAPI.verificationConfirmationResultCall = .success
            mockAPI.verificationConfirmationError = nil
            mockAPI.verificationConfirmationResponse = VerificationConfirmationResponse(
                projectId: projectId,
                accessId: accessId,
                actToken: actToken
            )
        }

        let activationTokenResponse = try await MIRACLTrust.getInstance().getActivationToken(userId: userId, code: code)
        #expect(activationTokenResponse.activationToken == actToken)
        #expect(activationTokenResponse.accessId == accessId)
        #expect(activationTokenResponse.projectId == projectId)
        #expect(activationTokenResponse.userId == userId)
    }

    @Test func getActivationTokenWithCodeError() async {
        let userId = UUID().uuidString
        let code = UUID().uuidString

        let cause = apiClientError(with: "Something is wrong")
        let desiredError = ActivationTokenError.getActivationTokenFail(cause)

        configureMockAPI { mockAPI in
            mockAPI.verificationConfirmationResultCall = .failed
            mockAPI.verificationConfirmationError = cause
            mockAPI.verificationConfirmationResponse = nil
        }

        let error = await #expect(throws: ActivationTokenError.self, performing: {
            try await MIRACLTrust.getInstance().getActivationToken(userId: userId, code: code)
        })

        #expect(error == desiredError)
    }

    @Test func getActivationTokenUserIdCodeCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await MIRACLTrust.getInstance().getActivationToken(userId: "", code: "")
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func generateQuickCode() async throws {
        let user = createUser()
        let quickCode = UUID().uuidString

        configureMockAPI { mockAPI in
            var pass1Response = Pass1Response()
            pass1Response.challenge = UUID().uuidString
            mockAPI.pass1Response = pass1Response

            var pass2Response = Pass2Response()
            pass2Response.authOTT = UUID().uuidString
            mockAPI.pass2Response = pass2Response

            var authenticateResponse = AuthenticateResponse()
            authenticateResponse.jwt = UUID().uuidString

            mockAPI.authenticationResponseManager.authenticateResponse = authenticateResponse
            mockAPI.verificationQuickCodeResponse = VerificationQuickCodeResponse(code: quickCode, expireTime: Date(), ttlSeconds: Int.random(in: 1 ... 999))
        }

        let returnedQuickCode = try await MIRACLTrust.getInstance().generateQuickCode(user: user) { processPinHandler in
            processPinHandler("1234")
        }
        #expect(quickCode == returnedQuickCode.code)
    }

    @Test func generateQuickCodeError() async {
        let user = createUser()

        let cause = apiClientError(with: "Something is wrong")
        let desiredError = QuickCodeError.generationFail(cause)

        configureMockAPI { mockAPI in
            var pass1Response = Pass1Response()
            pass1Response.challenge = UUID().uuidString
            mockAPI.pass1Response = pass1Response

            var pass2Response = Pass2Response()
            pass2Response.authOTT = UUID().uuidString
            mockAPI.pass2Response = pass2Response

            var authenticateResponse = AuthenticateResponse()
            authenticateResponse.jwt = UUID().uuidString

            mockAPI.authenticationResponseManager.authenticateResponse = authenticateResponse
            mockAPI.verificationQuickCodeResultCall = .failed
            mockAPI.verificationQuickCodeResponse = nil
            mockAPI.verificationQuickCodeError = cause
        }

        let error = await #expect(throws: QuickCodeError.self, performing: {
            try await MIRACLTrust.getInstance().generateQuickCode(user: user) { processPinHandler in
                processPinHandler("1234")
            }
        })
        #expect(error == desiredError)
    }

    @Test func generateQuickCodeCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await MIRACLTrust.getInstance().generateQuickCode(user: createUser()) { processPinHandler in
                processPinHandler("1234")
            }
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func register() async throws {
        let userId = UUID().uuidString
        let activationToken = UUID().uuidString

        configureMockAPI { mockAPI in
            let validRegistration = RegistrationResponse(
                mpinId: mpinId,
                projectId: projectId,
                designatedTAs: [
                    DesignatedTA(url: URL(string: "https://example.com")!, token: randomString),
                    DesignatedTA(url: URL(string: "https://example.com")!, token: randomString)
                ]
            )

            let taShareResponse = TAShareResponse(node: "DTA Node", share: randomString)

            mockAPI.registrationResponse = validRegistration
            mockAPI.taSharesResponsesManager.taShare1Response = taShareResponse
            mockAPI.taSharesResponsesManager.taShare2Response = taShareResponse
        }

        let user = try await MIRACLTrust.getInstance().register(userId: userId, activationToken: activationToken) { processPinHandler in
            processPinHandler("1234")
        }
        #expect(user.userId == userId)
        #expect(user.dtas == dtas)
        #expect(user.token == clientToken)
        #expect(user.mpinId == Data(hexString: mpinId))
        #expect(user.hashedMpinId == "d3ddd84f90ff4497df43534e0ab0813f71838f5ea92ba98705a84a0d6f593c8d")
    }

    @Test func registerError() async {
        let cause = apiClientError(with: "Something is wrong")
        let desiredError = RegistrationError.registrationFail(cause)

        configureMockAPI { mockAPI in
            mockAPI.registrationResponse = nil
            mockAPI.registrationError = cause
            mockAPI.registrationResultCall = .failed
        }

        let error = await #expect(throws: RegistrationError.self, performing: {
            try await MIRACLTrust.getInstance().register(userId: randomString, activationToken: randomString) { processPinHandler in
                processPinHandler("1234")
            }
        })
        #expect(error == desiredError)
    }

    @Test func registerCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await MIRACLTrust.getInstance().register(userId: "", activationToken: "") { processPinHandler in
                processPinHandler("1234")
            }
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func authenticate() async throws {
        let user = createUser()
        let jwt = UUID().uuidString

        configureMockAPI { mockAPI in
            var pass1Response = Pass1Response()
            pass1Response.challenge = UUID().uuidString
            mockAPI.pass1Response = pass1Response

            var pass2Response = Pass2Response()
            pass2Response.authOTT = UUID().uuidString
            mockAPI.pass2Response = pass2Response

            var authenticateResponse = AuthenticateResponse()
            authenticateResponse.jwt = jwt

            mockAPI.authenticationResponseManager.authenticateResponse = authenticateResponse
        }

        let jwtResponse = try await MIRACLTrust.getInstance().authenticate(user: user) { processPinHandler in
            processPinHandler("1234")
        }
        #expect(jwt == jwtResponse)
    }

    @Test func authenticateError() async {
        let user = createUser()

        let cause = apiClientError(with: "Something is wrong")
        let desiredError = AuthenticationError.authenticationFail(cause)

        configureMockAPI { mockAPI in
            var pass1Response = Pass1Response()
            pass1Response.challenge = UUID().uuidString
            mockAPI.pass1Response = pass1Response

            var pass2Response = Pass2Response()
            pass2Response.authOTT = UUID().uuidString
            mockAPI.pass2Response = pass2Response

            mockAPI.authenticationResponseManager.authenticateResponse = nil
            mockAPI.authenticationResponseManager.authenticateError = cause
        }

        let error = await #expect(throws: AuthenticationError.self, performing: {
            try await MIRACLTrust.getInstance().authenticate(user: user) { processPinHandler in
                processPinHandler("1234")
            }
        })
        #expect(error == desiredError)
    }

    @Test func authenticateCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await MIRACLTrust.getInstance().authenticate(user: createUser()) { processPinHandler in
                processPinHandler("1234")
            }
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func getCrossDeviceSessionFromQRCode() async throws {
        let accessId = "b227d0850d4280b98c5124a14aec84bf"
        let qrCode = "https://example.mpin.io#\(accessId)"

        configureMockAPI { mockAPI in
            mockAPI.crossDeviceSessionResponse = CrossDeviceSessionResponse(prerollId: randomString, projectId: randomString, signingHash: randomString, sessionDescription: randomString)
        }

        let crossDeviceSession = try await MIRACLTrust.getInstance().getCrossDeviceSessionFromQRCode(qrCode: qrCode)
        #expect(crossDeviceSession.userId == randomString)
        #expect(crossDeviceSession.projectId == randomString)
        #expect(crossDeviceSession.signingHash == randomString)
        #expect(crossDeviceSession.sessionDescription == randomString)
    }

    @Test func getCrossDeviceSessionFromQRCodeError() async {
        let qrCode = "https://example.mpin.io#b227d0850d4280b98c5124a14aec84bf"

        let cause = apiClientError(with: "Something is wrong")
        let desiredError = CrossDeviceSessionError.getCrossDeviceSessionFail(cause)

        configureMockAPI { mockAPI in
            mockAPI.crossDeviceSessionError = cause
        }

        let error = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await MIRACLTrust.getInstance().getCrossDeviceSessionFromQRCode(qrCode: qrCode)
        })
        #expect(error == desiredError)
    }

    @Test func getCrossDeviceSessionFromQRCodeCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await MIRACLTrust.getInstance().getCrossDeviceSessionFromQRCode(qrCode: "")
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func getCrossDeviceSessionFromUniversalLinkURL() async throws {
        let accessId = "b227d0850d4280b98c5124a14aec84bf"
        let universalLinkURL = try #require(URL(string: "https://example.mpin.io#\(accessId)"))

        configureMockAPI { mockAPI in
            mockAPI.crossDeviceSessionResponse = CrossDeviceSessionResponse(prerollId: randomString, projectId: randomString, signingHash: randomString, sessionDescription: randomString)
        }

        let crossDeviceSession = try await MIRACLTrust.getInstance().getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL: universalLinkURL)
        #expect(crossDeviceSession.userId == randomString)
        #expect(crossDeviceSession.projectId == randomString)
        #expect(crossDeviceSession.signingHash == randomString)
        #expect(crossDeviceSession.sessionDescription == randomString)
    }

    @Test func getCrossDeviceSessionFromUniversalLinkURLError() async throws {
        let universalLinkURL = try #require(URL(string: "https://example.mpin.io#b227d0850d4280b98c5124a14aec84bf"))

        let cause = apiClientError(with: "Something is wrong")
        let desiredError = CrossDeviceSessionError.getCrossDeviceSessionFail(cause)

        configureMockAPI { mockAPI in
            mockAPI.crossDeviceSessionError = cause
        }

        let error = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await MIRACLTrust.getInstance().getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL: universalLinkURL)
        })
        #expect(error == desiredError)
    }

    @Test func getCrossDeviceSessionFromUniversalLinkURLCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            let url = try #require(URL(string: "https://example.com"))
            return try await MIRACLTrust.getInstance().getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL: url)
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func getCrossDeviceSessionFromPushNotificationPayload() async throws {
        let accessId = "b227d0850d4280b98c5124a14aec84bf"
        let payload = ["qrURL": "https://mcl.mpin.io#\(accessId)"]

        configureMockAPI { mockAPI in
            mockAPI.crossDeviceSessionResponse = CrossDeviceSessionResponse(prerollId: randomString, projectId: randomString, signingHash: randomString, sessionDescription: randomString)
        }

        let crossDeviceSession = try await MIRACLTrust.getInstance().getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload: payload)
        #expect(crossDeviceSession.userId == randomString)
        #expect(crossDeviceSession.projectId == randomString)
        #expect(crossDeviceSession.signingHash == randomString)
        #expect(crossDeviceSession.sessionDescription == randomString)
        #expect(crossDeviceSession.sessionId == accessId)
    }

    @Test func getCrossDeviceSessionFromPushNotificationPayloadError() async {
        let payload = ["qrURL": "https://mcl.mpin.io#b227d0850d4280b98c5124a14aec84bf"]

        let cause = apiClientError(with: "Something is wrong")
        let desiredError = CrossDeviceSessionError.getCrossDeviceSessionFail(cause)

        configureMockAPI { mockAPI in
            mockAPI.crossDeviceSessionError = cause
        }

        let error = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await MIRACLTrust.getInstance().getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload: payload)
        })
        #expect(error == desiredError)
    }

    @Test func getCrossDeviceSessionFromPuhsNotificationPayloadCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await MIRACLTrust.getInstance().getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload: [:])
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func authenticateCrossDeviceSession() async throws {
        let crossDeviceSession = createCrossDeviceSession()
        let user = createUser()

        configureMockAPI { mockAPI in
            var pass1Response = Pass1Response()
            pass1Response.challenge = UUID().uuidString
            mockAPI.pass1Response = pass1Response

            var pass2Response = Pass2Response()
            pass2Response.authOTT = UUID().uuidString
            mockAPI.pass2Response = pass2Response

            var authenticateResponse = AuthenticateResponse()
            authenticateResponse.jwt = randomString

            mockAPI.authenticationResponseManager.authenticateResponse = authenticateResponse
        }

        try await MIRACLTrust.getInstance().authenticateCrossDeviceSession(crossDeviceSession: crossDeviceSession, user: user) { processPinHandler in
            processPinHandler("1234")
        }
    }

    @Test func authenticateCrossDeviceSessionError() async {
        let crossDeviceSession = createCrossDeviceSession()
        let user = createUser()

        let cause = apiClientError(with: "Something is wrong")
        let desiredError = AuthenticationError.authenticationFail(cause)

        configureMockAPI { mockAPI in
            var pass1Response = Pass1Response()
            pass1Response.challenge = UUID().uuidString
            mockAPI.pass1Response = pass1Response

            var pass2Response = Pass2Response()
            pass2Response.authOTT = UUID().uuidString
            mockAPI.pass2Response = pass2Response

            var authenticateResponse = AuthenticateResponse()
            authenticateResponse.jwt = randomString

            mockAPI.authenticationResponseManager.authenticateError = cause
        }

        let error = await #expect(throws: AuthenticationError.self, performing: {
            try await MIRACLTrust.getInstance().authenticateCrossDeviceSession(crossDeviceSession: crossDeviceSession, user: user) { processPinHandler in
                processPinHandler("1234")
            }
        })
        #expect(error == desiredError)
    }

    @Test func authenticateCrossDeviceSessionCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }

            let crossDeviceSession = createCrossDeviceSession()
            let user = createUser()
            return try await MIRACLTrust.getInstance().authenticateCrossDeviceSession(crossDeviceSession: crossDeviceSession, user: user) { processPinHandler in
                processPinHandler("1234")
            }
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func signCrossDeviceSession() async throws {
        let user = createUser()
        let crossDeviceSession = createCrossDeviceSession(signingHash: UUID().uuidString)

        configureMockAPI { mockAPI in
            var pass1Response = Pass1Response()
            pass1Response.challenge = UUID().uuidString
            mockAPI.pass1Response = pass1Response

            var pass2Response = Pass2Response()
            pass2Response.authOTT = UUID().uuidString
            mockAPI.pass2Response = pass2Response

            var authenticateResponse = AuthenticateResponse()
            authenticateResponse.jwt = randomString

            mockAPI.authenticationResponseManager.authenticateResponse = authenticateResponse

            mockAPI.updateCrossDeviceSessionError = nil
            mockAPI.updateCrossDeviceSessionResultCall = .success
        }

        try await MIRACLTrust.getInstance().signCrossDeviceSession(
            crossDeviceSession: crossDeviceSession,
            user: user
        ) { processPinHandler in
            processPinHandler("1234")
        }
    }

    @Test func signCrossDeviceSessionError() async {
        let user = createUser()
        let crossDeviceSession = createCrossDeviceSession(signingHash: UUID().uuidString)

        let cause = apiClientError(with: "Something is wrong")
        let desiredError = SigningError.signingFail(cause)

        configureMockAPI { mockAPI in
            var pass1Response = Pass1Response()
            pass1Response.challenge = UUID().uuidString
            mockAPI.pass1Response = pass1Response

            var pass2Response = Pass2Response()
            pass2Response.authOTT = UUID().uuidString
            mockAPI.pass2Response = pass2Response

            var authenticateResponse = AuthenticateResponse()
            authenticateResponse.jwt = randomString

            mockAPI.authenticationResponseManager.authenticateResponse = authenticateResponse

            mockAPI.updateCrossDeviceSessionError = cause
            mockAPI.updateCrossDeviceSessionResultCall = .success
        }

        let error = await #expect(throws: SigningError.self, performing: {
            try await MIRACLTrust.getInstance().signCrossDeviceSession(
                crossDeviceSession: crossDeviceSession,
                user: user
            ) { processPinHandler in
                processPinHandler("1234")
            }
        })
        #expect(error == desiredError)
    }

    @Test func signCrossDeviceSessionCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }

            let crossDeviceSession = createCrossDeviceSession()
            let user = createUser()
            return try await MIRACLTrust.getInstance().signCrossDeviceSession(crossDeviceSession: crossDeviceSession, user: user) { processPinHandler in
                processPinHandler("1234")
            }
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func abortCrossDeviceSession() async throws {
        let crossDeviceSession = createCrossDeviceSession()

        configureMockAPI { mockAPI in
            mockAPI.sessionAborterResultCall = .success
            mockAPI.sessionAborterError = nil
        }

        try await MIRACLTrust.getInstance().abortCrossDeviceSession(crossDeviceSession: crossDeviceSession)
    }

    @Test func abortCrossDeviceSessionError() async {
        let crossDeviceSession = createCrossDeviceSession()

        let cause = apiClientError(with: "Something is wrong")
        let desiredError = CrossDeviceSessionError.abortCrossDeviceSessionFail(cause)

        configureMockAPI { mockAPI in
            mockAPI.sessionAborterResultCall = .failed
            mockAPI.sessionAborterError = cause
        }

        let error = await #expect(throws: CrossDeviceSessionError.self, performing: {
            try await MIRACLTrust.getInstance().abortCrossDeviceSession(crossDeviceSession: crossDeviceSession)
        })
        #expect(error == desiredError)
    }

    @Test func abortCrossDeviceSessionCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }

            let crossDeviceSession = createCrossDeviceSession()
            return try await MIRACLTrust.getInstance().abortCrossDeviceSession(crossDeviceSession: crossDeviceSession)
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func sign() async throws {
        let user = createUser()
        let signingHash = try #require(UUID().uuidString.data(using: .utf8))

        configureMockAPI { mockAPI in
            var pass1Response = Pass1Response()
            pass1Response.challenge = UUID().uuidString
            mockAPI.pass1Response = pass1Response

            var pass2Response = Pass2Response()
            pass2Response.authOTT = UUID().uuidString
            mockAPI.pass2Response = pass2Response

            var authenticateResponse = AuthenticateResponse()
            authenticateResponse.jwt = randomString

            mockAPI.authenticationResponseManager.authenticateResponse = authenticateResponse
        }

        let signingResult = try await MIRACLTrust.getInstance().sign(message: signingHash, user: user) { processPinHAndler in
            processPinHAndler("1234")
        }
        #expect(signingResult.signature.mpinId == mpinId)
    }

    @Test func signError() async {
        let user = createUser()
        let signingHash = Data()
        let desiredError = SigningError.emptyMessageHash

        let error = await #expect(throws: SigningError.self, performing: {
            try await MIRACLTrust.getInstance().sign(message: signingHash, user: user) { processPinHandler in
                processPinHandler("1234")
            }
        })
        #expect(error == desiredError)
    }

    @Test func signCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }

            let user = createUser()
            let signingHash = Data()
            return try await MIRACLTrust.getInstance().sign(message: signingHash, user: user) { processPinHandler in
                processPinHandler("1234")
            }
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func getUser() async throws {
        let userId = UUID().uuidString
        let userDTO = createUserDTO(userId: userId)

        let userStorage = MockUserStorage()
        MIRACLTrust.getInstance().userStorage = userStorage
        try userStorage.add(user: userDTO)

        let user = try await MIRACLTrust.getInstance().getUser(userId: userId)
        #expect(user?.userId == userId)
        #expect(user?.projectId == projectId)
    }

    @Test func getUserNil() async throws {
        let userId = UUID().uuidString
        let userDTO = createUserDTO(userId: userId)

        let userStorage = MockUserStorage()
        MIRACLTrust.getInstance().userStorage = userStorage
        try userStorage.add(user: userDTO)

        let user = try await MIRACLTrust.getInstance().getUser(userId: UUID().uuidString)
        #expect(user == nil)
    }

    @Test func getUserError() async {
        let userStorage = MockUserStorage()
        userStorage.getUserThrowsError = true
        MIRACLTrust.getInstance().userStorage = userStorage

        let error = await #expect(throws: MockUserStorageError.self, performing: {
            try await MIRACLTrust.getInstance().getUser(userId: UUID().uuidString)
        })
        #expect(error == MockUserStorageError.testError)
    }

    @Test func getUserCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }

            return try await MIRACLTrust.getInstance().getUser(userId: "")
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func getUsers() async throws {
        let userId = UUID().uuidString
        let userDTO = createUserDTO(userId: userId)

        let userStorage = MockUserStorage()
        MIRACLTrust.getInstance().userStorage = userStorage
        try userStorage.add(user: userDTO)

        let users = try await MIRACLTrust.getInstance().getUsers()
        #expect(users.count == 1)
    }

    @Test func getUsersEmpty() async throws {
        let userStorage = MockUserStorage()
        MIRACLTrust.getInstance().userStorage = userStorage

        let users = try await MIRACLTrust.getInstance().getUsers()
        #expect(users.count == 0)
    }

    @Test func getUsersError() async {
        let userStorage = MockUserStorage()
        userStorage.getUsersThrowsError = true
        MIRACLTrust.getInstance().userStorage = userStorage

        let error = await #expect(throws: MockUserStorageError.self, performing: {
            try await MIRACLTrust.getInstance().getUsers()
        })
        #expect(error == MockUserStorageError.testError)
    }

    @Test func getUsersCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }

            return try await MIRACLTrust.getInstance().getUsers()
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func deleteUser() async throws {
        let userId = UUID().uuidString
        let userDTO = createUserDTO(userId: userId)

        let userStorage = MockUserStorage()
        try userStorage.add(user: userDTO)
        MIRACLTrust.getInstance().userStorage = userStorage

        let user = try await #require(MIRACLTrust.getInstance().getUser(userId: userId))
        try await MIRACLTrust.getInstance().delete(user: user)
        #expect(MIRACLTrust.getInstance().users.count == 0)
    }

    @Test func deleteUserError() async throws {
        let userId = UUID().uuidString
        let userDTO = createUserDTO(userId: userId)

        let userStorage = MockUserStorage()
        try userStorage.add(user: userDTO)
        userStorage.deleteUserThrowsError = true
        MIRACLTrust.getInstance().userStorage = userStorage

        let user = try await #require(MIRACLTrust.getInstance().getUser(userId: userId))
        let error = await #expect(throws: MockUserStorageError.self, performing: {
            try await MIRACLTrust.getInstance().delete(user: user)
        })
        #expect(error == MockUserStorageError.testError)
    }

    @Test func deleteUserCancellationError() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }

            return try await MIRACLTrust.getInstance().delete(user: createUser())
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    // MARK: Private

    private func createUser(userId: String = UUID().uuidString) -> User {
        User(
            userId: userId,
            projectId: UUID().uuidString,
            revoked: false,
            pinLength: 4,
            mpinId: Data(hexString: mpinId),
            token: clientToken,
            dtas: dtas,
            publicKey: Data([1, 2, 3])
        )
    }

    private func configureMockAPI(_ update: (inout MockAPI) -> Void) {
        var mockAPI = MockAPI()
        update(&mockAPI)
        MIRACLTrust.getInstance().miraclAPI = mockAPI
    }

    private func apiClientError(with code: String, context: [String: String]? = nil) -> APIError {
        let clientErrorData = ClientErrorData(
            code: code,
            info: "",
            context: context
        )

        return APIError.apiClientError(
            statusCode: 400,
            clientErrorData: clientErrorData,
            requestId: "",
            message: nil,
            requestURL: nil
        )
    }

    func createMockCrypto() -> MockCrypto {
        var crypto = MockCrypto()

        crypto.signingClientToken = clientToken
        crypto.clientPass1U = Data([0, 1, 2, 3])
        crypto.clientPass1S = Data([4, 5, 6, 7])
        crypto.clientPass1X = Data([8, 9, 10, 11])
        crypto.clientPass2V = Data([11, 12, 13])
        crypto.clientTokenData = Data([1, 2, 3])
        crypto.publicKey = Data([127, 128])
        crypto.privateKey = Data([1, 10, 127, 127])
        crypto.signingClientToken = clientToken
        crypto.signMessageU = Data([1, 2, 3])
        crypto.signMessageV = Data([1, 2, 3])

        return crypto
    }

    private func createCrossDeviceSession(signingHash: String = "") -> CrossDeviceSession {
        CrossDeviceSession(
            userId: UUID().uuidString,
            projectId: UUID().uuidString,
            sessionId: UUID().uuidString,
            sessionDescription: "",
            signingHash: signingHash
        )
    }

    private func createUserDTO(userId: String) -> UserDTO {
        UserDTO(
            userId: userId,
            projectId: projectId,
            revoked: false,
            pinLength: 4,
            mpinId: Data([1, 2, 3]),
            token: Data([1, 2, 3]),
            dtas: randomString,
            publicKey: nil
        )
    }
}
