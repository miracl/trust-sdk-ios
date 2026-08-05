@_spi(MIRACLTrustAuthenticatorApi) @testable import MIRACLTrust
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
    private var configuration: Configuration?

    private let backoff: Int64 = 1_688_029_968
    private let mpinId = "7b22696174223a313631373237323435332c22757365724944223a22676c6f62616c406578616d706c652e636f6d222c22634944223a2236636134636133622d623663342d343262332d386536372d336432653038616532643765222c2273616c74223a226d30756558414b4162566234425756742b5461745a51222c2276223a352c2273636f7065223a5b2261757468225d2c22647461223a5b5d2c227674223a227076227d"
    let dtas = "WyJEVEEgTm9kZSIsIkRUQSBOb2RlIl0="
    private let clientToken = Data([1, 2, 3])

    override func setUpWithError() throws {
        configuration = try Configuration
            .Builder(
                projectId: projectId,
                projectURL: projectURL
            )
            .userStorage(userStorage: mockUserStorage)
            .build()

        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

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
            projectId: projectId,
            designatedTAs: [
                DesignatedTA(url: URL(string: "https://example.com")!, token: randomString),
                DesignatedTA(url: URL(string: "https://example.com")!, token: randomString)
            ]
        )

        let taShareResponse = TAShareResponse(node: "DTA Node", share: randomString)

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
        sessionDetailResponse.quickCodeEnabled = true

        mockAPI.sessionDetailsResponse = sessionDetailResponse
        mockAPI.pass1Response = pass1Response
        mockAPI.pass2Response = pass2Response
        mockAPI.authenticationResponseManager.authenticateResponse = authenticateResponse

        mockAPI.registrationResponse = validRegistration
        mockAPI.taSharesResponsesManager.taShare1Response = taShareResponse
        mockAPI.taSharesResponsesManager.taShare2Response = taShareResponse
        mockAPI.verificationResponse = VerificationRequestResponse(backoff: backoff, method: "link")
        mockAPI.verificationConfirmationResponse = verificationConfirmationResponse
        mockAPI.sessionAborterResultCall = .success

        mockAPI.verificationResponse = VerificationRequestResponse(backoff: backoff, method: "link")
        mockAPI.verificationResultCall = .success
        mockAPI.verificationError = nil
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

    func testSendVerificationEmailWithCrossDeviceSession() {
        let completionHandlerExpectation = XCTestExpectation(description: "sendVerificationEmail with cross device session")
        let crossDeviceSession = createCrossDeviceSession()

        MIRACLTrust.getInstance().sendVerificationEmail(userId: randomString, crossDeviceSession: crossDeviceSession) { response, error in
            XCTAssertNil(error)
            XCTAssertNotNil(response)

            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testSendVerificationEmailWithAuthenticationSessionDetails() {
        let completionHandlerExpectation = XCTestExpectation(description: "sendVerificationEmail with authentication session")
        let authenticationSessionDetails = createSessionDetails()

        MIRACLTrust.getInstance().sendVerificationEmail(userId: randomString, authenticationSessionDetails: authenticationSessionDetails) { response, error in
            XCTAssertNil(error)
            XCTAssertNotNil(response)

            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testSendVerificationEmailWithoutCrossDeviceSession() {
        let completionHandlerExpectation = XCTestExpectation(description: "sendVerificationEmail without cross device session")

        MIRACLTrust.getInstance().sendVerificationEmail(userId: randomString) { response, error in
            XCTAssertNil(error)
            XCTAssertNotNil(response)

            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
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

    func testGetActivationTokenWithVerificationCode() {
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

    func testGetActivationTokenWithVerificationCodeValidationError() {
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
        let dtas = dtas

        MIRACLTrust.getInstance().register(for: userId, activationToken: activationToken) { processPinHandler in
            processPinHandler("1234")
            expectationForPinHandler.fulfill()
        } completionHandler: { user, error in
            XCTAssertEqual(Thread.current, Thread.main)
            XCTAssertNil(error)

            do {
                let user = try XCTUnwrap(user)

                XCTAssertEqual(user.userId, userId)
                XCTAssertEqual(user.dtas, dtas)
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

    func testAuthenticate() {
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
        try mockUserStorage.add(user: user.toUserDTO())

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
        try mockUserStorage.add(user: user.toUserDTO())

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

            } catch {
                XCTFail("Get session detail failed")
            }

            completionHandlerExpectation.fulfill()
        }

        wait(for: [completionHandlerExpectation], timeout: 20.0)
    }

    func testPushAuthenticationSessionDetailsError() {
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

    func testGetUser() throws {
        let userDTO = createUserDTO()
        try mockUserStorage.add(user: userDTO)
        let user = try XCTUnwrap(MIRACLTrust.getInstance().getUser(by: randomString))

        XCTAssertEqual(user.userId, userDTO.userId)
        XCTAssertEqual(user.projectId, userDTO.projectId)
        XCTAssertEqual(user.revoked, userDTO.revoked)
        XCTAssertEqual(user.pinLength, userDTO.pinLength)
        XCTAssertEqual(user.mpinId, userDTO.mpinId)
        XCTAssertEqual(user.token, userDTO.token)
        XCTAssertEqual(user.dtas, userDTO.dtas)
        XCTAssertEqual(user.publicKey, userDTO.publicKey)
    }

    func testGetNotExisitingUser() throws {
        projectId = randomString
        let userDTO = createUserDTO()

        try mockUserStorage.add(user: userDTO)
        XCTAssertNil(MIRACLTrust.getInstance().getUser(by: randomString))
    }

    func testDeleteUser() throws {
        let userDTO = createUserDTO()
        try mockUserStorage.add(user: userDTO)

        let user = try XCTUnwrap(MIRACLTrust.getInstance().getUser(by: randomString))
        try MIRACLTrust.getInstance().delete(user: user)

        XCTAssertTrue(MIRACLTrust.getInstance().users.count == 0)
    }

    func testGetUsers() throws {
        let userDTO = createUserDTO()
        try mockUserStorage.add(user: userDTO)
        XCTAssertTrue(MIRACLTrust.getInstance().users.count == 1)
    }

    func testGetUsersAsync() throws {
        let userDTO = createUserDTO()
        try mockUserStorage.add(user: userDTO)
        let expectation = XCTestExpectation(description: "Get all users asychrounisly")

        MIRACLTrust.getInstance().getUsers { users, error in
            XCTAssertEqual(users?.count, 1)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation])
    }

    func testGetUsersError() throws {
        let userDTO = createUserDTO()
        mockUserStorage.getUsersThrowsError = true
        try mockUserStorage.add(user: userDTO)
        let expectation = XCTestExpectation(description: "Get all users for error")

        MIRACLTrust.getInstance().getUsers { users, error in
            XCTAssertNil(users)
            XCTAssertNotNil(error)

            assertError(current: error, expected: MockUserStorageError.testError)
            expectation.fulfill()
        }

        wait(for: [expectation])
    }

    func testGetUserAsync() throws {
        let userDTO = createUserDTO()
        try mockUserStorage.add(user: userDTO)

        let expectation = XCTestExpectation(description: "Wait for user")
        let userId = randomString
        MIRACLTrust.getInstance().getUser(userId: userId) { user, error in
            do {
                XCTAssertNil(error)
                let user = try XCTUnwrap(user)

                XCTAssertEqual(user.userId, userDTO.userId)
                XCTAssertEqual(user.projectId, userDTO.projectId)
                XCTAssertEqual(user.revoked, userDTO.revoked)
                XCTAssertEqual(user.pinLength, userDTO.pinLength)
                XCTAssertEqual(user.mpinId, userDTO.mpinId)
                XCTAssertEqual(user.token, userDTO.token)
                XCTAssertEqual(user.dtas, userDTO.dtas)
                XCTAssertEqual(user.publicKey, userDTO.publicKey)

                expectation.fulfill()
            } catch {
                XCTFail("Error when getting user asynchronously = \(error)")
            }
        }

        wait(for: [expectation])
    }

    func testGetNotExisitingUserAsync() throws {
        projectId = randomString
        let userDTO = createUserDTO()

        try mockUserStorage.add(user: userDTO)

        let expectation = XCTestExpectation(description: "Wait for user")
        let userId = randomString

        MIRACLTrust.getInstance().getUser(userId: userId) { user, error in
            XCTAssertNil(user)
            XCTAssertNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation])
    }

    func testGetUserReturnsError() throws {
        let userDTO = createUserDTO()

        mockUserStorage.getUserThrowsError = true
        try mockUserStorage.add(user: userDTO)

        let expectation = XCTestExpectation(description: "Wait for user")
        let userId = randomString

        MIRACLTrust.getInstance().getUser(userId: userId) { user, error in
            XCTAssertNil(user)
            XCTAssertNotNil(error)
            assertError(current: error, expected: MockUserStorageError.testError)

            expectation.fulfill()
        }

        wait(for: [expectation])
    }

    func testDeleteUserAsync() throws {
        let userDTO = createUserDTO()
        try mockUserStorage.add(user: userDTO)

        let expectation = XCTestExpectation(description: "Wait for user")
        let userId = randomString

        let user = try XCTUnwrap(MIRACLTrust.getInstance().getUser(by: userId))

        MIRACLTrust.getInstance().delete(user: user) { isDeleted, error in
            XCTAssertTrue(isDeleted)
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation])

        XCTAssertTrue(MIRACLTrust.getInstance().users.count == 0)
    }

    func testDeleteUserThrowsErrorAsync() throws {
        mockUserStorage.deleteUserThrowsError = true

        let userDTO = createUserDTO()
        let expectation = XCTestExpectation(description: "Wait for user")

        let user = try XCTUnwrap(userDTO.toUser())

        MIRACLTrust.getInstance().delete(user: user) { isDeleted, error in
            XCTAssertFalse(isDeleted)
            assertError(current: error, expected: MockUserStorageError.testError)
            expectation.fulfill()
        }
        wait(for: [expectation])

        XCTAssertTrue(MIRACLTrust.getInstance().users.count == 0)
    }

    func testGetUsersStaticMethodCustomStorage() throws {
        MIRACLTrust.defaultUserStorage = nil
        MIRACLTrust.configuration = nil

        let configuration = try Configuration
            .Builder(
                projectId: projectId,
                projectURL: projectURL
            )
            .userStorage(userStorage: mockUserStorage)
            .build()
        try MIRACLTrust.setDefaultConfiguration(configuration)

        let userDTO = createUserDTO()
        try mockUserStorage.add(user: userDTO)

        let users = MIRACLTrust.getUsers()
        XCTAssertEqual(users.count, 1)
    }

    func testGetUsersStaticMethodDefaultUserStorageCreatedWithCreateInstance() throws {
        MIRACLTrust.defaultUserStorage = nil
        MIRACLTrust.configuration = nil

        let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let path = fileURL.appendingPathComponent("miracl.sqlite").relativePath
        let isFileExists = FileManager.default.fileExists(atPath: path)
        if isFileExists {
            try FileManager.default.removeItem(atPath: path)
        }

        let configuration = try Configuration
            .Builder()
            .build()
        try MIRACLTrust.setDefaultConfiguration(configuration)
        _ = try MIRACLTrust.createInstance(projectId: projectId, projectURL: projectURL)

        var users = MIRACLTrust.getUsers()
        XCTAssertEqual(users.count, 0)

        let userDTO = createUserDTO()
        try MIRACLTrust.defaultUserStorage?.add(user: userDTO)

        users = MIRACLTrust.getUsers()
        XCTAssertEqual(users.count, 1)
    }

    func testGetUsersStaticMethodDefaultUserStorageCreatedInMethod() throws {
        MIRACLTrust.defaultUserStorage = nil
        MIRACLTrust.configuration = nil

        let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let path = fileURL.appendingPathComponent("miracl.sqlite").relativePath
        let isFileExists = FileManager.default.fileExists(atPath: path)
        if isFileExists {
            try FileManager.default.removeItem(atPath: path)
        }

        let configuration = try Configuration
            .Builder()
            .build()
        try MIRACLTrust.setDefaultConfiguration(configuration)

        var users = MIRACLTrust.getUsers()
        XCTAssertEqual(users.count, 0)

        let userDTO = createUserDTO()
        try MIRACLTrust.defaultUserStorage?.add(user: userDTO)

        users = MIRACLTrust.getUsers()
        XCTAssertEqual(users.count, 1)
    }

    func testGetUsersStaticMethodDefaultUserStorageCreatedIfThereNoConfiguration() throws {
        MIRACLTrust.defaultUserStorage = nil
        MIRACLTrust.configuration = nil

        let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let path = fileURL.appendingPathComponent("miracl.sqlite").relativePath
        let isFileExists = FileManager.default.fileExists(atPath: path)
        if isFileExists {
            try FileManager.default.removeItem(atPath: path)
        }

        var users = MIRACLTrust.getUsers()
        XCTAssertEqual(users.count, 0)

        let userDTO = createUserDTO()
        try MIRACLTrust.defaultUserStorage?.add(user: userDTO)

        users = MIRACLTrust.getUsers()
        XCTAssertEqual(users.count, 1)
    }

    func testGetUsersStaticMethodThrowsError() throws {
        MIRACLTrust.defaultUserStorage = nil
        MIRACLTrust.configuration = nil

        let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let path = fileURL.appendingPathComponent("miracl.sqlite").relativePath
        let isFileExists = FileManager.default.fileExists(atPath: path)
        if isFileExists {
            try FileManager.default.removeItem(atPath: path)
        }

        let configuration = try Configuration
            .Builder(
                projectId: projectId,
                projectURL: projectURL
            )
            .userStorage(userStorage: mockUserStorage)
            .build()
        try MIRACLTrust.setDefaultConfiguration(configuration)

        mockUserStorage.getUsersThrowsError = true

        let users = MIRACLTrust.getUsers()
        XCTAssertEqual(users.count, 0)
    }

    // MARK: Private

    private func createUserDTO() -> UserDTO {
        UserDTO(
            userId: randomString,
            projectId: projectId,
            revoked: false,
            pinLength: 4,
            mpinId: Data([1, 2, 3]),
            token: Data([1, 2, 3]),
            dtas: randomString,
            publicKey: nil
        )
    }

    private func createUser(userId: String = UUID().uuidString) -> User {
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

    private func createSessionDetails(
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
            identityType: .email,
            accessId: accessId
        )
    }

    private func createCrossDeviceSession() -> CrossDeviceSession {
        CrossDeviceSession(
            userId: UUID().uuidString,
            projectId: UUID().uuidString,
            sessionId: UUID().uuidString,
            sessionDescription: "",
            signingHash: ""
        )
    }
}
