@testable import MIRACLTrust
import XCTest

enum TestJsonMalformedError: Error {
    case fail
}

class RegistratorTests: XCTestCase {
    var didRequestPinHandler: PinRequestHandler = { pinHandler in
        let pinCode = Int.random(in: 1000 ..< 9999)
        pinHandler(String(pinCode))
    }

    var crypto = mockCrypto()
    var userId = NSUUID().uuidString
    var dtas = NSUUID().uuidString
    var projectId = UUID().uuidString
    var storage: UserStorage = MockUserStorage()
    var activationToken = UUID().uuidString
    var mockAPI = MockAPI()
    var clientToken = Data([1, 2, 3])
    var mpinId = "7b22696174223a313631373237323435332c22757365724944223a22676c6f62616c406578616d706c652e636f6d222c22634944223a2236636134636133622d623663342d343262332d386536372d336432653038616532643765222c2273616c74223a226d30756558414b4162566234425756742b5461745a51222c2276223a352c2273636f7065223a5b2261757468225d2c22647461223a5b5d2c227674223a227076227d"
    let hashOfMpinId = "d3ddd84f90ff4497df43534e0ab0813f71838f5ea92ba98705a84a0d6f593c8d"
    var randomString = NSUUID().uuidString

    override func setUpWithError() throws {
        crypto = RegistratorTests.mockCrypto()
        crypto.clientTokenData = clientToken
        userId = NSUUID().uuidString
        dtas = NSUUID().uuidString
        activationToken = UUID().uuidString
        mockAPI = createMockAPI()

        let configuration = try Configuration
            .Builder(
                projectId: projectId
            )
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: configuration)
    }

    func testRegistrationSuccessful() throws {
        let userId = userId
        let dtas = dtas
        let clientToken = clientToken
        let mpinId = mpinId
        let hashOfMpinId = hashOfMpinId

        try register(completionHandler: { user, error in
            do {
                let user = try XCTUnwrap(user)

                XCTAssertEqual(user.userId, userId)
                XCTAssertEqual(user.dtas, dtas)
                XCTAssertEqual(user.token, clientToken)
                XCTAssertEqual(user.mpinId, Data(hexString: mpinId))
                XCTAssertEqual(user.hashedMpinId, hashOfMpinId)
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }
        })
    }

    func testOverrideExistingAuthenticationUser() throws {
        let expectation = XCTestExpectation(description: "Cannot create Registrator.")

        let userId = userId
        let dtasCopy = dtas
        let clientToken = clientToken
        let mpinIdCopy = mpinId
        let hashOfMpinId = hashOfMpinId

        try register(completionHandler: { user, error in
            XCTAssertNil(error)
            do {
                let user = try XCTUnwrap(user)

                XCTAssertEqual(user.userId, userId)
                XCTAssertEqual(user.dtas, dtasCopy)
                XCTAssertEqual(user.token, clientToken)
                XCTAssertEqual(user.mpinId, Data(hexString: mpinIdCopy))
                XCTAssertEqual(user.hashedMpinId, hashOfMpinId)
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }

            expectation.fulfill()
        })

        wait(for: [expectation], timeout: 20.0)

        activationToken = UUID().uuidString

        let newDtas = NSUUID().uuidString
        dtas = newDtas
        mpinId = "7b22696174223a313632313431373839312c22757365724944223a22383631303732393532222c22634944223a2261623938653665382d326133652d346438632d623831322d323636306433633337373433222c2273616c74223a22486f7063634d7a6a794b53705279616d535333316351222c2276223a352c2273636f7065223a5b2261757468225d2c22647461223a5b5d2c227674223a227076227d"
        let mpinIdUpdatedCopy = mpinId
        mockAPI = createMockAPI()

        let newToken = Data([3, 4, 5])
        crypto = RegistratorTests.mockCrypto()
        crypto.signingClientToken = newToken

        let expectation1 = XCTestExpectation(description: "Cannot create Registrator.")
        try register(completionHandler: { user, error in
            do {
                let user = try XCTUnwrap(user)

                XCTAssertEqual(user.userId, userId)
                XCTAssertEqual(user.dtas, newDtas)
                XCTAssertEqual(user.token, newToken)
                XCTAssertEqual(user.mpinId, Data(hexString: mpinIdUpdatedCopy))
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }

            expectation1.fulfill()
        })
        wait(for: [expectation1], timeout: 20.0)
    }

    func testRegistrationFailedWithEmptyOrBlankUserId() {
        XCTAssertThrowsError(try Registrator(userId: "",
                                             activationToken: activationToken,
                                             deviceName: randomString,
                                             api: mockAPI,
                                             userStorage: storage,
                                             projectId: NSUUID().uuidString,
                                             didRequestPinHandler: didRequestPinHandler,
                                             completionHandler: { _, _ in })) { error in
            XCTAssertTrue(error is RegistrationError)
            XCTAssertEqual(error as? RegistrationError, RegistrationError.emptyUserId)
        }

        XCTAssertThrowsError(try Registrator(userId: " ",
                                             activationToken: activationToken,
                                             deviceName: randomString,
                                             api: mockAPI,
                                             userStorage: storage,
                                             projectId: NSUUID().uuidString,
                                             didRequestPinHandler: didRequestPinHandler,
                                             completionHandler: { _, _ in })) { error in
            XCTAssertTrue(error is RegistrationError)
            XCTAssertEqual(error as? RegistrationError, RegistrationError.emptyUserId)
        }
    }

    func testRegisterUserBadStatusCodeRequest() throws {
        let expectedCause = APIError.apiServerError(statusCode: 400, message: nil, requestURL: nil)

        let desiredError = RegistrationError.registrationFail(expectedCause)
        mockAPI.registerUserError = expectedCause
        mockAPI.registrationResponse = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterUserInvalidActivationTokenError() throws {
        let desiredError = RegistrationError.invalidActivationToken

        mockAPI.registerUserError = apiClientError(with: "INVALID_ACTIVATION_TOKEN")
        mockAPI.registrationResponse = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterUserMalformedJSONRequest() throws {
        let testError = TestJsonMalformedError.fail
        let expectedCause = APIError.apiMalformedJSON(testError, nil)

        let desiredError = RegistrationError.registrationFail(expectedCause)

        mockAPI.registerUserError = expectedCause
        mockAPI.registrationResponse = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterNoRegistrationResponse() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        let invalidRegistrationResponse = RegistrationResponse(
            mpinId: "",
            regOTT: "",
            projectId: projectId
        )

        mockAPI.registerUserError = nil
        mockAPI.registrationResponse = invalidRegistrationResponse

        try register(completionHandler: { user, error in
            XCTAssertNil(user)

            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterInvalidRegistrationResponse() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        let invalidRegistrationResponse = RegistrationResponse(
            mpinId: "  ",
            regOTT: "  ",
            projectId: projectId
        )

        mockAPI.registerUserError = nil
        mockAPI.registrationResponse = invalidRegistrationResponse

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterInvalidRegistrationResponseWithSpaces() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        let invalidRegistrationResponse = RegistrationResponse(
            mpinId: "  ",
            regOTT: "  ",
            projectId: projectId
        )

        mockAPI.registerUserError = nil
        mockAPI.registrationResponse = invalidRegistrationResponse

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterFailedSignatureRequest() throws {
        let expectedCause = APIError.apiServerError(statusCode: 500, message: nil, requestURL: nil)

        let desiredError = RegistrationError.registrationFail(expectedCause)

        mockAPI = createMockAPI()
        mockAPI.signatureError = expectedCause
        mockAPI.signatureResponse = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterFailedSignatureRequestWithNoData() throws {
        let expectedCause = APIError.executionError("No data when request is succesful.", nil)

        let desiredError = RegistrationError.registrationFail(expectedCause)

        mockAPI = createMockAPI()
        mockAPI.signatureError = expectedCause
        mockAPI.signatureResponse = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterFailedSignatureMalformedJSON() throws {
        let exampleError = TestJsonMalformedError.fail
        let expectedCause = APIError.apiMalformedJSON(exampleError, nil)

        let desiredError = RegistrationError.registrationFail(expectedCause)

        mockAPI = createMockAPI()
        mockAPI.signatureError = expectedCause
        mockAPI.signatureResponse = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterInvalidSignatureResponse() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        mockAPI = createMockAPI()
        mockAPI.signatureError = nil
        mockAPI.signatureResponse = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterEmptySignatureResponse() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        mockAPI = createMockAPI()
        mockAPI.signatureError = nil
        mockAPI.signatureResponse = SignatureResponse()

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterInvalidSignatureResponseEmptyClientSecret() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        var emptySignatureResponse = SignatureResponse()
        emptySignatureResponse.dvsClientSecretShare = "   "
        emptySignatureResponse.curve = "BN254CX"
        emptySignatureResponse.dtas = NSUUID().uuidString

        mockAPI = createMockAPI()
        mockAPI.signatureError = nil
        mockAPI.signatureResponse = emptySignatureResponse

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterInvalidSignatureResponseEmptyCurve() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        var emptySignatureResponse = SignatureResponse()
        emptySignatureResponse.dvsClientSecretShare = NSUUID().uuidString
        emptySignatureResponse.curve = " "
        emptySignatureResponse.dtas = NSUUID().uuidString

        mockAPI = createMockAPI()
        mockAPI.signatureError = nil
        mockAPI.signatureResponse = emptySignatureResponse

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterInvalidSignatureResponseUnsupportedCurve() throws {
        let desiredError = RegistrationError.unsupportedEllipticCurve

        var emptySignatureResponse = SignatureResponse()
        emptySignatureResponse.dvsClientSecretShare = NSUUID().uuidString
        emptySignatureResponse.curve = "BLS48556"
        emptySignatureResponse.dtas = NSUUID().uuidString

        mockAPI = createMockAPI()
        mockAPI.signatureError = nil
        mockAPI.signatureResponse = emptySignatureResponse

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterInvalidSignatureResponseEmptyDtas() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        var emptySignatureResponse = SignatureResponse()
        emptySignatureResponse.dvsClientSecretShare = NSUUID().uuidString
        emptySignatureResponse.curve = "BN254CX"
        emptySignatureResponse.dtas = " "

        mockAPI = createMockAPI()
        mockAPI.signatureError = nil
        mockAPI.signatureResponse = emptySignatureResponse

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterInvalidSignatureResponseNoURL() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        var emptySignatureResponse = SignatureResponse()
        emptySignatureResponse.dvsClientSecretShare = NSUUID().uuidString
        emptySignatureResponse.curve = "BN254CX"
        emptySignatureResponse.dtas = NSUUID().uuidString
        emptySignatureResponse.cs2URL = nil

        mockAPI = createMockAPI()
        mockAPI.signatureError = nil
        mockAPI.signatureResponse = emptySignatureResponse

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterInvalidSignatureResponseWrongURL() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        var emptySignatureResponse = SignatureResponse()
        emptySignatureResponse.dvsClientSecretShare = NSUUID().uuidString
        emptySignatureResponse.curve = "BN254CX"
        emptySignatureResponse.dtas = NSUUID().uuidString
        if #available(iOS 17.0, *) {
            emptySignatureResponse.cs2URL = URL(string: "not url", encodingInvalidCharacters: false)
        } else {
            emptySignatureResponse.cs2URL = URL(string: "not url")
        }

        mockAPI = createMockAPI()
        mockAPI.signatureError = nil
        mockAPI.signatureResponse = emptySignatureResponse

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterGetClientSecret2BadStatusCode() throws {
        let expectedCause = APIError.apiServerError(statusCode: 500, message: nil, requestURL: nil)
        let desiredError = RegistrationError.registrationFail(expectedCause)

        mockAPI = createMockAPI()
        mockAPI.clientSecretError = expectedCause

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterGetClientSecret2InvalidResponse() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        mockAPI = createMockAPI()
        mockAPI.clientSecretResponse = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterGetClientSecret2EmptySecret() throws {
        let desiredError = RegistrationError.registrationFail(nil)
        mockAPI = createMockAPI()

        var clientSecretResponse = ClientSecretResponse()
        clientSecretResponse.dvsClientSecret = ""
        mockAPI.clientSecretResponse = clientSecretResponse

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterGetClientSecret2SpacesSecret() throws {
        let desiredError = RegistrationError.registrationFail(nil)
        mockAPI = createMockAPI()

        var clientSecretResponse = ClientSecretResponse()
        clientSecretResponse.dvsClientSecret = "  \n  "
        mockAPI.clientSecretResponse = clientSecretResponse

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterGetTokenShortPIN() throws {
        let desiredError = RegistrationError.invalidPin
        didRequestPinHandler = { pinProcessor in
            pinProcessor("123")
        }

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterGetTokenLongerPIN() throws {
        let desiredError = RegistrationError.invalidPin
        didRequestPinHandler = { pinProcessor in
            pinProcessor("1234567890")
        }

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterGetTokenNilPIN() throws {
        let desiredError = RegistrationError.pinCancelled
        didRequestPinHandler = { pinProcessor in
            pinProcessor(nil)
        }

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterGetWrongClientToken() throws {
        let expectedCause = CryptoError.getClientTokenError(info: "")

        let desiredError = RegistrationError.registrationFail(expectedCause)

        crypto = RegistratorTests.mockCrypto()
        crypto.signingClientTokenError = expectedCause

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegisterInvalidClientToken() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        crypto = RegistratorTests.mockCrypto()
        crypto.signingClientToken = Data()

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testEmptyActivationToken() throws {
        XCTAssertThrowsError(try Registrator(userId: userId,
                                             activationToken: "",
                                             deviceName: randomString,
                                             api: mockAPI,
                                             userStorage: storage,
                                             projectId: NSUUID().uuidString,
                                             didRequestPinHandler: didRequestPinHandler,
                                             completionHandler: { _, _ in })) { error in
            XCTAssertTrue(error is RegistrationError)
            XCTAssertEqual(error as? RegistrationError, RegistrationError.emptyActivationToken)
        }
    }

    func testProjectMismatch() throws {
        let desiredError = RegistrationError.projectMismatch
        let randomString = UUID().uuidString

        let projectMismatchRegistrationResponse = RegistrationResponse(
            mpinId: mpinId,
            regOTT: randomString,
            projectId: randomString
        )

        mockAPI.registrationResponse = projectMismatchRegistrationResponse

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testNilRegistrationResponse() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        mockAPI.registrationResponse = nil
        mockAPI.registerUserError = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    // MARK: Private

    private func register(completionHandler: @escaping RegistrationCompletionHandler) throws {
        let expectation = XCTestExpectation(description: "Cannot create Registrator.")

        let registrator = try Registrator(
            userId: userId,
            activationToken: activationToken,
            api: mockAPI,
            crypto: crypto,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { user, error in
                completionHandler(user, error)

                expectation.fulfill()
            }
        )
        registrator.register()
        wait(for: [expectation], timeout: 20.0)
    }

    private class func mockCrypto() -> MockCrypto {
        var mockCrypto = MockCrypto()
        mockCrypto.signingClientToken = Data([1, 2, 3])
        return mockCrypto
    }

    private func createMockAPI() -> MockAPI {
        let randomString = NSUUID().uuidString

        let validRegistration = RegistrationResponse(
            mpinId: mpinId,
            regOTT: randomString,
            projectId: projectId
        )

        var emptySignatureResponse = SignatureResponse()
        emptySignatureResponse.dvsClientSecretShare = randomString
        emptySignatureResponse.curve = "BN254CX"
        emptySignatureResponse.dtas = dtas
        emptySignatureResponse.cs2URL = URL(string: "https://www.example.com")

        var clientSecretResponse = ClientSecretResponse()
        clientSecretResponse.dvsClientSecret = randomString

        var mockAPI = MockAPI()
        mockAPI.registrationResponse = validRegistration
        mockAPI.signatureResponse = emptySignatureResponse
        mockAPI.clientSecretResponse = clientSecretResponse

        return mockAPI
    }

    private func getDBFilePath() -> String {
        var path = ""
        do {
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            path = fileURL.appendingPathComponent("miracl-test.sqlite").relativePath
        } catch {
            XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
        }

        return path
    }

    private func apiClientError(with code: String, context: [String: String]? = nil) -> APIError {
        let clientErrorData = ClientErrorData(
            code: code,
            info: "",
            context: context
        )

        return APIError.apiClientError(
            clientErrorData: clientErrorData,
            requestId: "",
            message: nil,
            requestURL: nil
        )
    }
}
