@testable import MIRACLTrust
import XCTest

class MIRACLTrustTests: XCTestCase {
    private var projectId = UUID().uuidString
    private var clientId = UUID().uuidString
    private var redirectURI = UUID().uuidString
    private var mockUserStorage = MockUserStorage()
    private var mockAPI = MockAPI()
    private var crypto = MockCrypto()
    private var randomString = UUID().uuidString
    private var randomBool = Bool.random()
    private var currentDate = Int64(Date().timeIntervalSince1970)
    private var user: User?

    private let backoff: Int64 = 1_688_029_968
    private let mpinId = "7b22696174223a313631373237323435332c22757365724944223a22676c6f62616c406578616d706c652e636f6d222c22634944223a2236636134636133622d623663342d343262332d386536372d336432653038616532643765222c2273616c74223a226d30756558414b4162566234425756742b5461745a51222c2276223a352c2273636f7065223a5b2261757468225d2c22647461223a5b5d2c227674223a227076227d"
    private let clientToken = Data([1, 2, 3])

    override func setUpWithError() throws {
        let configuration = try Configuration
            .Builder(
                projectId: projectId
            )
            .userStorage(userStorage: mockUserStorage)
            .build()

        try MIRACLTrust.configure(with: configuration)

        createMockAPI()
        createMockCrypto()
        user = createUser()

        mockUserStorage = MockUserStorage()

        MIRACLTrust.getInstance().userStorage = mockUserStorage
        MIRACLTrust.getInstance().miraclAPI = mockAPI
        MIRACLTrust.getInstance().crypto = crypto
    }

    func createMockAPI() {
        mockAPI = MockAPI()
        var verificationConfirmationResponse = VerificationConfirmationResponse()
        verificationConfirmationResponse.accessId = randomString
        verificationConfirmationResponse.actToken = randomString
        verificationConfirmationResponse.projectId = randomString

        let validRegistration = RegistrationResponse(
            mpinId: mpinId,
            regOTT: UUID().uuidString,
            projectId: projectId
        )

        var emptySignatureResponse = SignatureResponse()
        emptySignatureResponse.dvsClientSecretShare = randomString
        emptySignatureResponse.curve = "BN254CX"
        emptySignatureResponse.dtas = randomString
        emptySignatureResponse.cs2URL = URL(string: "https://www.example.com")

        var clientSecretResponse = ClientSecretResponse()
        clientSecretResponse.dvsClientSecret = randomString

        var pass1Response = Pass1Response()
        pass1Response.challenge = randomString

        var pass2Response = Pass2Response()
        pass2Response.authOTT = randomString

        let responseCode = randomString
        var authenticateResponse = AuthenticateResponse()
        authenticateResponse.jwt = responseCode

        var sessionDetailResponse = AuthenticationSessionsDetailsResponse()

        sessionDetailResponse.prerollId = randomString
        sessionDetailResponse.projectId = randomString
        sessionDetailResponse.projectName = randomString
        sessionDetailResponse.projectLogoURL = randomString
        sessionDetailResponse.pinLength = 4
        sessionDetailResponse.verificationURL = randomString
        sessionDetailResponse.verificationMethod = "fullCustom"
        sessionDetailResponse.verificationCustomText = randomString
        sessionDetailResponse.identityTypeLabel = randomString
        sessionDetailResponse.identityType = "email"
        sessionDetailResponse.limitQuickCodeRegistration = true
        sessionDetailResponse.quickCodeEnabled = true

        let signingSessionDetailsResponse = SigningSessionDetailsResponse(
            userID: randomString,
            signingHash: randomString,
            signingDescription: randomString,
            status: "active",
            expireTime: currentDate,
            projectId: randomString,
            projectName: randomString,
            projectLogoURL: randomString,
            verificationMethod: "standardEmail",
            verificationURL: randomString,
            verificationCustomText: randomString,
            identityType: "email",
            identityTypeLabel: randomString,
            pinLength: 4,
            enableRegistrationCode: randomBool,
            limitRegCodeVerified: randomBool
        )

        mockAPI.signingSessionDetailsResponse = signingSessionDetailsResponse
        mockAPI.sessionDetailsResponse = sessionDetailResponse
        mockAPI.pass1Response = pass1Response
        mockAPI.pass2Response = pass2Response
        mockAPI.authenticationResponseManager.authenticateResponse = authenticateResponse
        mockAPI.registrationResponse = validRegistration
        mockAPI.signatureResponse = emptySignatureResponse
        mockAPI.clientSecretResponse = clientSecretResponse
        mockAPI.verificationResponse = VerificationRequestResponse(backoff: backoff, method: "link")
        mockAPI.verificationConfirmationResponse = verificationConfirmationResponse
        mockAPI.sessionAborterResultCall = .success
        mockAPI.signingSessionAborterResultCall = .success

        mockAPI.signingSessionCompleterError = nil
        mockAPI.signingSessionCompleterResultCall = .success
        mockAPI.signingSessionCompleterResponse = SigningSessionCompleterResponse(status: "signed")
    }

    func createMockCrypto() {
        crypto = MockCrypto()

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
    }

    func testSendVerificationMail() {
        let userId = UUID().uuidString
        let expectation = XCTestExpectation(description: "sendVerificationEmail")

        let backoff = backoff

        MIRACLTrust.getInstance().sendVerificationEmail(userId: userId) { verified, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNotNil(verified)
            XCTAssertNil(error)

            do {
                let response = try XCTUnwrap(verified)
                XCTAssertEqual(response.backoff, backoff)
            } catch {
                XCTFail("Cannot unwrap Verification Response")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func testSendVerificationMailValidationError() {
        let userId = ""
        let expectation = XCTestExpectation(description: "sendVerificationEmail - fail")
        MIRACLTrust.getInstance().sendVerificationEmail(userId: userId) { response, error in
            XCTAssertEqual(Thread.current, Thread.main)

            XCTAssertNil(response)
            assertError(current: error, expected: VerificationError.emptyUserId)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func testGetActivationToken() throws {
        let userId = "alice@miracl.com"
        let verificationURL = try XCTUnwrap(URL(string: "https://api.mpin.io/verification/confirmation?code=af1cc549573718409de44d8bf2e67a06&user_id=\(userId)"))
        let expectation = XCTestExpectation(description: "getActivationToken")

        let randomString = randomString

        MIRACLTrust.getInstance().getActivationToken(verificationURL: verificationURL) { activationTokenResponse, error in

            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(error)

            do {
                let response = try XCTUnwrap(activationTokenResponse)
                let activationToken = try XCTUnwrap(response.activationToken)
                XCTAssertEqual(activationToken, randomString)

                XCTAssertNotNil(response.userId)
                XCTAssertEqual(userId, response.userId)

                XCTAssertNotNil(response.accessId)
                XCTAssertEqual(randomString, response.accessId)

                XCTAssertNotNil(response.projectId)
                XCTAssertEqual(randomString, response.projectId)
            } catch {
                XCTFail("Cannot unwrap activation token - \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func testGetActivationTokenValidationError() throws {
        let verificationURL = try XCTUnwrap(URL(string: "https://api.mpin.io/verification/confirmation?code=af1cc549573718409de44d8bf2e67a06"))
        let expectation = XCTestExpectation(description: "getActivationToken - fail")

        MIRACLTrust.getInstance().getActivationToken(verificationURL: verificationURL) { _, error in
            XCTAssertEqual(Thread.current, Thread.main)
            assertError(current: error, expected: ActivationTokenError.emptyUserId)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func testGetActivationTokenWithVerificationCode() throws {
        let userId = "alice@miracl.com"
        let code = "af1cc549573718409de44d8bf2e67a06"
        let expectation = XCTestExpectation(description: "testGetActivationTokenWithVerificationCode")

        let randomString = randomString

        MIRACLTrust.getInstance().getActivationToken(userId: userId, code: code) { activationTokenResponse, error in

            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(error)

            do {
                let response = try XCTUnwrap(activationTokenResponse)
                let activationToken = try XCTUnwrap(response.activationToken)
                XCTAssertEqual(activationToken, randomString)

                XCTAssertNotNil(response.userId)
                XCTAssertEqual(userId, response.userId)

                XCTAssertNotNil(response.accessId)
                XCTAssertEqual(randomString, response.accessId)

                XCTAssertNotNil(response.projectId)
                XCTAssertEqual(randomString, response.projectId)
            } catch {
                XCTFail("Cannot unwrap activation token - \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func testGetActivationTokenWithVerificationCodeValidationError() throws {
        let userId = ""
        let code = "af1cc549573718409de44d8bf2e67a06"
        let expectation = XCTestExpectation(description: "getActivationToken - fail")

        MIRACLTrust.getInstance().getActivationToken(userId: userId, code: code) { _, error in
            XCTAssertEqual(Thread.current, Thread.main)
            assertError(current: error, expected: ActivationTokenError.emptyUserId)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func testRegister() {
        let userId = UUID().uuidString
        let activationToken = UUID().uuidString

        let expectation = XCTestExpectation(description: "register")
        let expectationForPinHandler = XCTestExpectation(description: "register - pinHandler")

        let randomString = randomString
        let clientToken = clientToken
        let mpinId = mpinId

        MIRACLTrust.getInstance().register(for: userId, activationToken: activationToken) { processPinHandler in
            processPinHandler("1234")
            expectationForPinHandler.fulfill()
        } completionHandler: { user, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(error)

            do {
                let user = try XCTUnwrap(user)

                XCTAssertEqual(user.userId, userId)
                XCTAssertEqual(user.dtas, randomString)
                XCTAssertEqual(user.token, clientToken)
                XCTAssertEqual(user.mpinId, Data(hexString: mpinId))
                XCTAssertEqual(user.hashedMpinId, "d3ddd84f90ff4497df43534e0ab0813f71838f5ea92ba98705a84a0d6f593c8d")
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectationForPinHandler, expectation], timeout: 20.0)
    }

    func testRegisterForValidationError() {
        let emptyUserId = ""
        let activationToken = ""

        let expectation = XCTestExpectation(description: "register - fail")

        MIRACLTrust.getInstance().register(for: emptyUserId, activationToken: activationToken) { processPinHandler in
            processPinHandler("1234")
        } completionHandler: { user, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(user)

            assertError(current: error, expected: RegistrationError.emptyUserId)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func testAuthenticate() throws {
        let pinHandlerExpectation = XCTestExpectation(description: "authenticate")
        let completionHandlerExpectation = XCTestExpectation(description: "authenticate - pinhandler")

        let randomString = randomString

        MIRACLTrust.getInstance().authenticate(user: createUser()) { processPinHandler in
            processPinHandler("1234")
            pinHandlerExpectation.fulfill()
        } completionHandler: { jwt, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertEqual(jwt, randomString)
            XCTAssertNil(error)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [pinHandlerExpectation, completionHandlerExpectation], timeout: 20.0)
    }

    func testAuthenticateForEmptyUser() {
        let user = createUser(userId: "")

        let completionHandlerExpectation = XCTestExpectation(description: "authenticate - fail")

        MIRACLTrust.getInstance().authenticate(user: user) { processPinHandler in
            processPinHandler("1234")
        } completionHandler: { jwt, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(jwt)
            assertError(current: error, expected: AuthenticationError.invalidUserData)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testQRAuthenticate() throws {
        let completionHandlerExpectation = XCTestExpectation(description: "qrauthenticate")
        let pinHandlerExpectation = XCTestExpectation(description: "qrauthenticate - pinhandlder")

        let qrCode = "https://mcl.mpin.io#b227d0850d4280b98c5124a14aec84bf"

        try MIRACLTrust.getInstance().authenticateWithQRCode(
            user: XCTUnwrap(user),
            qrCode: qrCode
        ) { processPinHandler in
            processPinHandler("1234")
            pinHandlerExpectation.fulfill()
        } completionHandler: { authenticated, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertTrue(authenticated)
            XCTAssertNil(error)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [pinHandlerExpectation, completionHandlerExpectation], timeout: 20.0)
    }

    func testQRAuthenticateWithValidationError() throws {
        let qrCode = "https://mcl.mpin.io#"
        let completionHandlerExpectation = XCTestExpectation(description: "qrauthenticate - fail")

        try MIRACLTrust.getInstance().authenticateWithQRCode(
            user: XCTUnwrap(user),
            qrCode: qrCode
        ) { processPinHandler in
            processPinHandler("1234")
        } completionHandler: { authenticated, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertFalse(authenticated)
            assertError(current: error, expected: AuthenticationError.invalidQRCode)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testPushAuthenticate() throws {
        let user = createUser()
        try mockUserStorage.add(user: user)

        let qrCode = "https://mcl.mpin.io#b227d0850d4280b98c5124a14aec84bf"
        let payload = [
            "userID": user.userId,
            "projectID": randomString,
            "qrURL": qrCode
        ]

        let completionHandlerExpectation = XCTestExpectation(description: "pushauthenticate")
        let pinHandlerExpectation = XCTestExpectation(description: "pushauthenticate - pinhandler")

        MIRACLTrust.getInstance().authenticateWithPushNotificationPayload(payload: payload) { processPinHandler in
            processPinHandler("1234")
            pinHandlerExpectation.fulfill()
        } completionHandler: { authenticated, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertTrue(authenticated)
            XCTAssertNil(error)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [pinHandlerExpectation, completionHandlerExpectation], timeout: 20.0)
    }

    func testPushAuthenticateWithValidationError() throws {
        let user = createUser()
        try mockUserStorage.add(user: user)

        let qrCode = "https://mcl.mpin.io#"
        let payload = [
            "userID": user.userId,
            "projectID": randomString,
            "qrURL": qrCode
        ]

        let completionHandlerExpectation = XCTestExpectation(description: "pushauthenticate - fail")

        MIRACLTrust.getInstance().authenticateWithPushNotificationPayload(payload: payload) { processPinHandler in
            processPinHandler("1234")
        } completionHandler: { authenticated, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertFalse(authenticated)
            assertError(current: error, expected: AuthenticationError.invalidPushNotificationPayload)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testUniversalLinkURKAuthenticate() throws {
        let qrCode = try XCTUnwrap(URL(string: "https://mcl.mpin.io#b227d0850d4280b98c5124a14aec84bf"))

        let completionHandlerExpectation = XCTestExpectation(description: "universallinkauthenticate")
        let pinHandlerExpectation = XCTestExpectation(description: "universallinkauthenticate - pinhandler")

        try MIRACLTrust.getInstance().authenticateWithUniversalLinkURL(
            user: XCTUnwrap(user),
            universalLinkURL: qrCode
        ) { processPinHandler in
            processPinHandler("1234")
            pinHandlerExpectation.fulfill()
        } completionHandler: { authenticated, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertTrue(authenticated)
            XCTAssertNil(error)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [pinHandlerExpectation, completionHandlerExpectation], timeout: 20.0)
    }

    func testUniversalLinkURLAuthenticateWithValidationError() throws {
        let qrCode = try XCTUnwrap(URL(string: "https://mcl.mpin.io#"))

        let completionHandlerExpectation = XCTestExpectation(description: "universallinkauthenticate - fail")

        try MIRACLTrust.getInstance().authenticateWithUniversalLinkURL(
            user: XCTUnwrap(user),
            universalLinkURL: qrCode
        ) { processPinHandler in
            processPinHandler("1234")
        } completionHandler: { authenticated, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertFalse(authenticated)
            assertError(current: error, expected: AuthenticationError.invalidUniversalLink)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testGenerateQuickCode() throws {
        var authenticateResponse = AuthenticateResponse()
        authenticateResponse.jwt = UUID().uuidString

        mockAPI.authenticationResponseManager.authenticateResponse = authenticateResponse
        mockAPI.verificationQuickCodeResponse = VerificationQuickCodeResponse(code: UUID().uuidString, expireTime: Date(), ttlSeconds: Int.random(in: 1 ... 999))

        MIRACLTrust.getInstance().miraclAPI = mockAPI
        let pinHandlerExpectation = XCTestExpectation(description: "quickcode - pinhandler")
        let completionHandlerExpectation = XCTestExpectation(description: "quickcode")

        try MIRACLTrust.getInstance().generateQuickCode(user: XCTUnwrap(user)) { processPinHandler in
            processPinHandler("1234")
            pinHandlerExpectation.fulfill()
        } completionHandler: { quickCode, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(error)
            XCTAssertNotNil(quickCode)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testGenerateQuickCodeForError() {
        let user = createUser(userId: "")

        let completionHandlerExpectation = XCTestExpectation(description: "quickcode - fail")

        MIRACLTrust.getInstance().generateQuickCode(user: user) { processPinHandler in
            processPinHandler("1234")

        } completionHandler: { quickCode, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(quickCode)
            assertError(current: error, expected: QuickCodeError.generationFail(AuthenticationError.invalidUserData))
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testQRAuthenticationSessionDetails() {
        let accessId = "b227d0850d4280b98c5124a14aec84bf"
        let qrCode = "https://mcl.mpin.io#\(accessId)"

        let expectation = XCTestExpectation(description: "qrsessiondetails")

        let randomString = randomString

        MIRACLTrust.getInstance().getAuthenticationSessionDetailsFromQRCode(qrCode: qrCode) { sessionDetails, _ in
            XCTAssertEqual(Thread.current, Thread.main)
            do {
                let fetchedDetails = try XCTUnwrap(sessionDetails)

                XCTAssertEqual(fetchedDetails.userId, randomString)
                XCTAssertEqual(fetchedDetails.projectId, randomString)
                XCTAssertEqual(fetchedDetails.projectName, randomString)
                XCTAssertEqual(fetchedDetails.projectLogoURL, randomString)
                XCTAssertEqual(fetchedDetails.accessId, accessId)
                XCTAssertEqual(fetchedDetails.pinLength, 4)
                XCTAssertEqual(fetchedDetails.verificationMethod, .fullCustom)
                XCTAssertEqual(fetchedDetails.verificationURL, randomString)
                XCTAssertEqual(fetchedDetails.identityTypeLabel, randomString)
                XCTAssertEqual(fetchedDetails.verificationCustomText, randomString)
                XCTAssertEqual(fetchedDetails.identityType, IdentityType.email)
                XCTAssertEqual(fetchedDetails.quickCodeEnabled, true)
                XCTAssertEqual(fetchedDetails.limitQuickCodeRegistration, true)

                expectation.fulfill()
            } catch {
                XCTFail("Get session detail failed")
            }
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func testQRAuthenticationSessionDetailsError() {
        let accessId = ""
        let qrCode = "https://mcl.mpin.io#\(accessId)"

        let expectation = XCTestExpectation(description: "qrsessiondetails - fail")

        MIRACLTrust.getInstance().getAuthenticationSessionDetailsFromQRCode(qrCode: qrCode) { sessionDetails, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(sessionDetails)
            assertError(current: error, expected: AuthenticationSessionError.invalidQRCode)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func testUniversalLinkURLAuthenticationSessionDetails() throws {
        let accessId = "b227d0850d4280b98c5124a14aec84bf"
        let qrCode = try XCTUnwrap(URL(string: "https://mcl.mpin.io#\(accessId)"))

        let expectation = XCTestExpectation(description: "universallinkauthenticationsession")

        let randomString = randomString

        MIRACLTrust.getInstance().getAuthenticationSessionDetailsFromUniversalLinkURL(universalLinkURL: qrCode) { sessionDetails, _ in
            XCTAssertEqual(Thread.current, Thread.main)
            do {
                let fetchedDetails = try XCTUnwrap(sessionDetails)

                XCTAssertEqual(fetchedDetails.userId, randomString)
                XCTAssertEqual(fetchedDetails.projectId, randomString)
                XCTAssertEqual(fetchedDetails.projectName, randomString)
                XCTAssertEqual(fetchedDetails.projectLogoURL, randomString)

                XCTAssertEqual(fetchedDetails.accessId, accessId)
                XCTAssertEqual(fetchedDetails.pinLength, 4)
                XCTAssertEqual(fetchedDetails.verificationMethod, .fullCustom)
                XCTAssertEqual(fetchedDetails.verificationURL, randomString)
                XCTAssertEqual(fetchedDetails.identityTypeLabel, randomString)
                XCTAssertEqual(fetchedDetails.verificationCustomText, randomString)
                XCTAssertEqual(fetchedDetails.identityType, IdentityType.email)
                XCTAssertEqual(fetchedDetails.quickCodeEnabled, true)
                XCTAssertEqual(fetchedDetails.limitQuickCodeRegistration, true)

                expectation.fulfill()
            } catch {
                XCTFail("Get session detail failed")
            }
        }

        wait(for: [expectation], timeout: 20.0)
    }

    func testUniversalLinkURLAuthenticationSessionDetailsError() throws {
        let accessId = ""
        let qrCode = try XCTUnwrap(URL(string: "https://mcl.mpin.io#\(accessId)"))
        let completionHandlerExpectation = XCTestExpectation(description: "universallinkauthenticationsession - fail")

        MIRACLTrust.getInstance().getAuthenticationSessionDetailsFromUniversalLinkURL(universalLinkURL: qrCode) { sessionDetails, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(sessionDetails)
            assertError(current: error, expected: AuthenticationSessionError.invalidUniversalLinkURL)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func tesPushAuthenticationSessionDetails() throws {
        let accessId = "b227d0850d4280b98c5124a14aec84bf"
        let payload = ["qrURL": "https://mcl.mpin.io#\(accessId)"]

        let completionHandlerExpectation = XCTestExpectation(description: "pushauthenticationsession")

        let randomString = randomString

        MIRACLTrust.getInstance().getAuthenticationSessionDetailsFromPushNotificationPayload(pushNotificationPayload: payload) { sessionDetails, _ in
            XCTAssertEqual(Thread.current, Thread.main)
            do {
                let fetchedDetails = try XCTUnwrap(sessionDetails)

                XCTAssertEqual(fetchedDetails.userId, randomString)
                XCTAssertEqual(fetchedDetails.projectId, randomString)
                XCTAssertEqual(fetchedDetails.projectName, randomString)
                XCTAssertEqual(fetchedDetails.projectLogoURL, randomString)
                XCTAssertEqual(fetchedDetails.accessId, accessId)
                XCTAssertEqual(fetchedDetails.pinLength, 4)
                XCTAssertEqual(fetchedDetails.verificationMethod, .fullCustom)
                XCTAssertEqual(fetchedDetails.verificationURL, randomString)
                XCTAssertEqual(fetchedDetails.identityTypeLabel, randomString)
                XCTAssertEqual(fetchedDetails.verificationCustomText, randomString)
                XCTAssertEqual(fetchedDetails.identityType, IdentityType.email)
                XCTAssertEqual(fetchedDetails.quickCodeEnabled, true)
                XCTAssertEqual(fetchedDetails.limitQuickCodeRegistration, true)

            } catch {
                XCTFail("Get session detail failed")
            }

            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testPushAuthenticationSessionDetailsError() throws {
        let accessId = ""
        let payload = ["qrURL": "https://mcl.mpin.io#\(accessId)"]

        let completionHandlerExpectation = XCTestExpectation(description: "pushauthenticationsession - fail")

        MIRACLTrust.getInstance().getAuthenticationSessionDetailsFromPushNotificationPayload(pushNotificationPayload: payload) { sessionDetails, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(sessionDetails)
            assertError(current: error, expected: AuthenticationSessionError.invalidPushNotificationPayload)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testQRSigningSession() {
        let sessionId = "b227d0850d4280b98c5124a14aec84bf"
        let qrCode = "https://mobile.int.miracl.net/dvs#\(sessionId)"

        let completionHandlerExpectation = XCTestExpectation(description: "qrsigningsession")

        let randomString = randomString
        let randomBool = randomBool
        let currentDate = currentDate

        MIRACLTrust.getInstance().getSigningSessionDetailsFromQRCode(qrCode: qrCode) { signingSessionDetails, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(error)
            XCTAssertNotNil(signingSessionDetails)

            do {
                let unwrappedSessionDetails = try XCTUnwrap(signingSessionDetails)
                XCTAssertEqual(unwrappedSessionDetails.userId, randomString)
                XCTAssertEqual(unwrappedSessionDetails.signingHash, randomString)
                XCTAssertEqual(unwrappedSessionDetails.signingDescription, randomString)
                XCTAssertEqual(unwrappedSessionDetails.status, SigningSessionStatus.active)
                XCTAssertEqual(unwrappedSessionDetails.projectId, randomString)
                XCTAssertEqual(unwrappedSessionDetails.projectName, randomString)
                XCTAssertEqual(unwrappedSessionDetails.projectLogoURL, randomString)
                XCTAssertEqual(unwrappedSessionDetails.verificationMethod, VerificationMethod.standardEmail)
                XCTAssertEqual(unwrappedSessionDetails.verificationURL, randomString)
                XCTAssertEqual(unwrappedSessionDetails.verificationCustomText, randomString)
                XCTAssertEqual(unwrappedSessionDetails.identityType, IdentityType.email)
                XCTAssertEqual(unwrappedSessionDetails.identityTypeLabel, randomString)
                XCTAssertEqual(unwrappedSessionDetails.pinLength, 4)
                XCTAssertEqual(unwrappedSessionDetails.quickCodeEnabled, randomBool)
                XCTAssertEqual(unwrappedSessionDetails.limitQuickCodeRegistration, randomBool)
                XCTAssertEqual(unwrappedSessionDetails.expireTime, Date(timeIntervalSince1970: TimeInterval(currentDate)))
            } catch {
                XCTFail("No signingSessionDetails object")
            }
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testQRSigningSessionForError() {
        let sessionId = ""
        let qrCode = "https://mobile.int.miracl.net/dvs#\(sessionId)"

        let completionHandlerExpectation = XCTestExpectation(description: "qrsigningsession - fail")

        MIRACLTrust.getInstance().getSigningSessionDetailsFromQRCode(qrCode: qrCode) { signingSessionDetails, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(signingSessionDetails)
            assertError(current: error, expected: SigningSessionError.invalidQRCode)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testUniversalLinkURLSigningSession() throws {
        let sessionId = "b227d0850d4280b98c5124a14aec84bf"
        let qrCode = try XCTUnwrap(URL(string: "https://mobile.int.miracl.net/dvs#\(sessionId)"))

        let completionHandlerExpectation = XCTestExpectation(description: "universallinksigningsession")

        let randomString = randomString
        let randomBool = randomBool
        let currentDate = currentDate

        MIRACLTrust.getInstance().getSigningSessionDetailsFromUniversalLinkURL(universalLinkURL: qrCode) { signingSessionDetails, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(error)
            XCTAssertNotNil(signingSessionDetails)

            do {
                let unwrappedSessionDetails = try XCTUnwrap(signingSessionDetails)
                XCTAssertEqual(unwrappedSessionDetails.userId, randomString)
                XCTAssertEqual(unwrappedSessionDetails.signingHash, randomString)
                XCTAssertEqual(unwrappedSessionDetails.signingDescription, randomString)
                XCTAssertEqual(unwrappedSessionDetails.status, SigningSessionStatus.active)
                XCTAssertEqual(unwrappedSessionDetails.projectId, randomString)
                XCTAssertEqual(unwrappedSessionDetails.projectName, randomString)
                XCTAssertEqual(unwrappedSessionDetails.projectLogoURL, randomString)
                XCTAssertEqual(unwrappedSessionDetails.verificationMethod, VerificationMethod.standardEmail)
                XCTAssertEqual(unwrappedSessionDetails.verificationURL,
                               randomString)
                XCTAssertEqual(unwrappedSessionDetails.verificationCustomText, randomString)
                XCTAssertEqual(unwrappedSessionDetails.identityType, IdentityType.email)
                XCTAssertEqual(unwrappedSessionDetails.identityTypeLabel, randomString)
                XCTAssertEqual(unwrappedSessionDetails.pinLength, 4)
                XCTAssertEqual(unwrappedSessionDetails.quickCodeEnabled, randomBool)
                XCTAssertEqual(unwrappedSessionDetails.limitQuickCodeRegistration, randomBool)
                XCTAssertEqual(unwrappedSessionDetails.expireTime, Date(timeIntervalSince1970: TimeInterval(currentDate)))
            } catch {
                XCTFail("No signingSessionDetails object")
            }
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testUniversalLinkURLSigningSessionForError() throws {
        let sessionId = ""
        let qrCode = try XCTUnwrap(URL(string: "https://mobile.int.miracl.net/dvs#\(sessionId)"))

        let completionHandlerExpectation = XCTestExpectation(description: "universallinksigningsession - fail")

        MIRACLTrust.getInstance().getSigningSessionDetailsFromUniversalLinkURL(universalLinkURL: qrCode) { signingSessionDetails, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(signingSessionDetails)
            assertError(current: error, expected: SigningSessionError.invalidUniversalLinkURL)
            completionHandlerExpectation.fulfill()
        }
        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testAbortAuthenticationSession() {
        let sessionDetails = createSessionDetails()

        let completionHandlerExpectation = XCTestExpectation(description: "abortauthenticationsession")

        MIRACLTrust.getInstance().abortAuthenticationSession(authenticationSessionDetails: sessionDetails) { aborted, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertTrue(aborted)
            XCTAssertNil(error)

            completionHandlerExpectation.fulfill()
        }
        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testAbortAuthenticationSessionError() {
        let sessionDetails = createSessionDetails(accessId: "")

        let completionHandlerExpectation = XCTestExpectation(description: "abortauthenticationsession - fail")

        MIRACLTrust.getInstance().abortAuthenticationSession(authenticationSessionDetails: sessionDetails) { aborted, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertFalse(aborted)
            assertError(current: error, expected: AuthenticationSessionError.invalidAuthenticationSessionDetails)
            completionHandlerExpectation.fulfill()
        }
        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testAbortSigningSession() {
        let sessionDetails = createSigningSessionDetails()

        let completionHandlerExpectation = XCTestExpectation(description: "abortsigningsession")

        MIRACLTrust.getInstance().abortSigningSession(signingSessionDetails: sessionDetails) { aborted, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertTrue(aborted)
            XCTAssertNil(error)

            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testAbortSigningSessionError() {
        let sessionDetails = createSigningSessionDetails(sessionId: "")

        let completionHandlerExpectation = XCTestExpectation(description: "abortsigningsession - fail")
        MIRACLTrust.getInstance().abortSigningSession(signingSessionDetails: sessionDetails) { aborted, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertFalse(aborted)
            assertError(current: error, expected: SigningSessionError.invalidSigningSessionDetails)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testSign() throws {
        let message = try XCTUnwrap(UUID().uuidString.data(using: .utf8))
        let user = User(
            userId: randomString,
            projectId: randomString,
            revoked: false,
            pinLength: 4,
            mpinId: Data(hexString: mpinId),
            token: clientToken,
            dtas: randomString,
            publicKey: Data([1, 2, 3])
        )

        let pinHandlerExpectation = XCTestExpectation(description: "sign - pinhandler")
        let completionHandlerExpectation = XCTestExpectation(description: "sign")

        MIRACLTrust.getInstance().sign(message: message, user: user) { processPinHandler in
            processPinHandler("1234")
            pinHandlerExpectation.fulfill()
        } completionHandler: { signatureResult, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(error)
            XCTAssertNotNil(signatureResult)

            completionHandlerExpectation.fulfill()
        }

        wait(for: [pinHandlerExpectation, completionHandlerExpectation], timeout: 20.0)
    }

    func testSignError() throws {
        let message = Data()
        let completionHandlerExpectation = XCTestExpectation(description: "sign - fail")

        try MIRACLTrust.getInstance().sign(message: message, user: XCTUnwrap(user)) { processPinHandler in
            processPinHandler("1234")
        } completionHandler: { signatureResult, error in
            XCTAssertEqual(Thread.current, Thread.main)
            assertError(current: error, expected: SigningError.emptyMessageHash)
            XCTAssertNil(signatureResult)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testSignSigningSessionDetails() throws {
        let message = try XCTUnwrap(UUID().uuidString.data(using: .utf8))
        let user = createUser()
        let signingSessionDetails = createSigningSessionDetails()

        let pinHandlerExpectation = XCTestExpectation(description: "sign - pinhandler")
        let completionHandlerExpectation = XCTestExpectation(description: "sign")

        MIRACLTrust.getInstance()._sign(
            message: message,
            user: user,
            signingSessionDetails: signingSessionDetails
        ) { processPinHandler in
            processPinHandler("1234")
            pinHandlerExpectation.fulfill()
        } completionHandler: { signature, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(error)
            XCTAssertNotNil(signature)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [pinHandlerExpectation, completionHandlerExpectation], timeout: 20.0)
    }

    func testSignErrorSigningSessionDetails() throws {
        let message = Data()
        let signingSessionDetails = createSigningSessionDetails()
        let completionHandlerExpectation = XCTestExpectation(description: "sign - fail")

        try MIRACLTrust.getInstance()._sign(
            message: message,
            user: XCTUnwrap(user),
            signingSessionDetails: signingSessionDetails
        ) { processPinHandler in
            processPinHandler("1234")
        } completionHandler: { signature, error in
            XCTAssertEqual(Thread.current, Thread.main)
            assertError(current: error, expected: SigningError.emptyMessageHash)
            XCTAssertNil(signature)
            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func createUser(userId: String = UUID().uuidString) -> User {
        User(
            userId: userId,
            projectId: randomString,
            revoked: false,
            pinLength: 4,
            mpinId: Data(hexString: mpinId),
            token: clientToken,
            dtas: randomString,
            publicKey: Data([1, 2, 3])
        )
    }

    func createSessionDetails(
        accessId: String = "b227d0850d4280b98c5124a14aec84bf"
    ) -> AuthenticationSessionDetails {
        AuthenticationSessionDetails(
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
            accessId: accessId
        )
    }

    func createSigningSessionDetails(sessionId: String = "b227d0850d4280b98c5124a14aec84bf") -> SigningSessionDetails {
        SigningSessionDetails(
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
            limitQuickCodeRegistration: true,
            identityType: .email,
            sessionId: sessionId,
            signingHash: UUID().uuidString,
            signingDescription: UUID().uuidString,
            status: .signed,
            expireTime: Date()
        )
    }
}
