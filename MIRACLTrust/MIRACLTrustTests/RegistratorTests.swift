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
                projectId: projectId,
                projectURL: projectURL
            )
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: configuration)
    }

    func testRegistratorSuccessful() throws {
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

    func testRegistratorOverrideExisitngUser() throws {
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

    func testRegistratorEmptyOrBlankUserId() {
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

        XCTAssertThrowsError(try Registrator(userId: userId,
                                             activationToken: " ",
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

    func testRegistratorKeyPairError() throws {
        let expectedCause = CryptoError.generateSigningKeypairError(info: "")
        let desiredError = RegistrationError.registrationFail(expectedCause)

        crypto = RegistratorTests.mockCrypto()
        crypto.keyPairError = expectedCause

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorInvalidActivationTokenError() throws {
        let desiredError = RegistrationError.invalidActivationToken

        mockAPI.registrationError = apiClientError(with: "INVALID_ACTIVATION_TOKEN")
        mockAPI.registrationResponse = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorErrorInRegistrationResponse() throws {
        let testError = TestJsonMalformedError.fail
        let expectedCause = APIError.apiMalformedJSON(testError, nil)

        let desiredError = RegistrationError.registrationFail(expectedCause)

        mockAPI.registrationError = expectedCause
        mockAPI.registrationResponse = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorNilRegistrationResponse() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        mockAPI.registrationError = nil
        mockAPI.registrationResponse = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorProjectMismatch() throws {
        let desiredError = RegistrationError.projectMismatch

        mockAPI.registrationResponse?.projectId = UUID().uuidString
        mockAPI.registrationError = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorWrongElipticCurve() throws {
        let desiredError = RegistrationError.unsupportedEllipticCurve

        mockAPI.registrationResponse?.curve = UUID().uuidString
        mockAPI.registrationError = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorEmptySecretUrls() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        mockAPI.registrationResponse?.secretUrls = []
        mockAPI.registrationError = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorInvalidClientSecretURLs() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        // Invalid URL is at [0]
        mockAPI.registrationResponse?.secretUrls = [
            "https:// example. com/my endpoint ",
            "https://example.com"
        ]
        mockAPI.registrationError = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })

        // Invalid URL is at [1]
        mockAPI.registrationResponse?.secretUrls = [
            "https://example.com",
            "https:// example. com/my endpoint "
        ]

        mockAPI.registrationError = nil
        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorErrorOnFirstClientSecretRequest() throws {
        let cause = TestJsonMalformedError.fail
        let desiredError = RegistrationError.registrationFail(cause)

        mockAPI.clientSecretResponsesManager.clientSecret1Error = TestJsonMalformedError.fail
        mockAPI.clientSecretResponsesManager.clientSecret1Response = nil
        mockAPI.clientSecretResponsesManager.clientSecret1ResultCall = .failed

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorNilResponseOnFirstClientSecretRequest() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        mockAPI.clientSecretResponsesManager.clientSecret1Error = nil
        mockAPI.clientSecretResponsesManager.clientSecret1Response = nil
        mockAPI.clientSecretResponsesManager.clientSecret1ResultCall = .failed

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorErrorOnSecondClientSecretRequest() throws {
        let cause = TestJsonMalformedError.fail
        let desiredError = RegistrationError.registrationFail(cause)

        mockAPI.clientSecretResponsesManager.clientSecret2Error = TestJsonMalformedError.fail
        mockAPI.clientSecretResponsesManager.clientSecret2Response = nil
        mockAPI.clientSecretResponsesManager.clientSecret2ResultCall = .failed

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorWithRetry() throws {
        let cause = APIError.executionError("", nil)

        mockAPI.clientSecretResponsesManager.retryInProgress = false
        mockAPI.clientSecretResponsesManager.retryEnabled = true

        mockAPI.clientSecretResponsesManager.clientSecret1ResultCall = .failed
        mockAPI.clientSecretResponsesManager.clientSecret1Response = nil
        mockAPI.clientSecretResponsesManager.clientSecret1Error = cause

        mockAPI.clientSecretResponsesManager.clientSecret1RetryResultCall = .success
        mockAPI.clientSecretResponsesManager.clientSecret1RetryResponse = ClientSecretResponse(dvsClientSecret: UUID().uuidString)
        mockAPI.clientSecretResponsesManager.clientSecret1RetryError = nil

        try register(completionHandler: { user, error in
            do {
                let user = try XCTUnwrap(user)

                XCTAssertEqual(user.userId, self.userId)
                XCTAssertEqual(user.dtas, self.dtas)
                XCTAssertEqual(user.token, self.clientToken)
                XCTAssertEqual(user.mpinId, Data(hexString: self.mpinId))
                XCTAssertEqual(user.hashedMpinId, self.hashOfMpinId)
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }
        })
    }

    func testRegistratorWithRetryForSecondClientSecretRequest() throws {
        let cause = APIError.executionError("", nil)

        mockAPI.clientSecretResponsesManager.retryEnabledForSecondClientSecret = true

        mockAPI.clientSecretResponsesManager.clientSecret1ResultCall = .success
        mockAPI.clientSecretResponsesManager.clientSecret1Response = ClientSecretResponse(dvsClientSecret: UUID().uuidString)
        mockAPI.clientSecretResponsesManager.clientSecret1Error = nil

        mockAPI.clientSecretResponsesManager.clientSecret2ResultCall = .failed
        mockAPI.clientSecretResponsesManager.clientSecret2Response = nil
        mockAPI.clientSecretResponsesManager.clientSecret2Error = cause

        mockAPI.clientSecretResponsesManager.clientSecret2RetryResultCall = .success
        mockAPI.clientSecretResponsesManager.clientSecret2RetryResponse = ClientSecretResponse(dvsClientSecret: UUID().uuidString)
        mockAPI.clientSecretResponsesManager.clientSecret2RetryError = nil

        try register(completionHandler: { user, error in
            do {
                let user = try XCTUnwrap(user)

                XCTAssertEqual(user.userId, self.userId)
                XCTAssertEqual(user.dtas, self.dtas)
                XCTAssertEqual(user.token, self.clientToken)
                XCTAssertEqual(user.mpinId, Data(hexString: self.mpinId))
                XCTAssertEqual(user.hashedMpinId, self.hashOfMpinId)
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }
        })
    }

    func testRegistratorExecutionErrorForSecondRequest() throws {
        let cause = APIError.executionError("", nil)
        let desiredError = RegistrationError.registrationFail(cause)

        mockAPI.clientSecretResponsesManager.retryEnabledForSecondClientSecret = true

        mockAPI.clientSecretResponsesManager.clientSecret1ResultCall = .success
        mockAPI.clientSecretResponsesManager.clientSecret1Response = ClientSecretResponse(dvsClientSecret: UUID().uuidString)
        mockAPI.clientSecretResponsesManager.clientSecret1Error = nil

        mockAPI.clientSecretResponsesManager.clientSecret2ResultCall = .failed
        mockAPI.clientSecretResponsesManager.clientSecret2Response = nil
        mockAPI.clientSecretResponsesManager.clientSecret2Error = cause

        mockAPI.clientSecretResponsesManager.clientSecret2RetryResultCall = .failed
        mockAPI.clientSecretResponsesManager.clientSecret2RetryResponse = nil
        mockAPI.clientSecretResponsesManager.clientSecret2RetryError = cause

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorStringPIN() throws {
        let desiredError = RegistrationError.invalidPin
        didRequestPinHandler = { pinProcessor in
            pinProcessor("nil")
        }

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorNilPIN() throws {
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

    func testRegistratorShortPIN() throws {
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

    func testRegistratorLongerPIN() throws {
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

    func testRegistratorErrorOneSecretURL() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        mockAPI.registrationResponse?.secretUrls = ["https://example.com"]

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorCryptoClientTokenError() throws {
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

    func testRegistratorEmptyDataClientToken() throws {
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

        var clientSecretResponse = ClientSecretResponse()
        clientSecretResponse.dvsClientSecret = randomString

        let registrationResponse2 = RegistrationResponse(
            mpinId: mpinId,
            projectId: projectId,
            dtas: dtas,
            curve: "BN254CX",
            secretUrls: [
                "https://www.example.com",
                "https://www.example1.com"
            ]
        )

        var mockAPI = MockAPI()
        mockAPI.registrationResponse = registrationResponse2

        mockAPI.clientSecretResponsesManager.clientSecret1ResultCall = .success
        mockAPI.clientSecretResponsesManager.clientSecret1Error = nil
        mockAPI.clientSecretResponsesManager.clientSecret1Response = ClientSecretResponse(dvsClientSecret: UUID().uuidString)

        mockAPI.clientSecretResponsesManager.clientSecret2ResultCall = .success
        mockAPI.clientSecretResponsesManager.clientSecret2Error = nil
        mockAPI.clientSecretResponsesManager.clientSecret2Response = ClientSecretResponse(dvsClientSecret: UUID().uuidString)

        return mockAPI
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
}
