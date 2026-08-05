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

    var projectId = UUID().uuidString
    var storage: UserStorage = MockUserStorage()
    var activationToken = UUID().uuidString
    var mockAPI = MockAPI()
    var clientToken = Data([1, 2, 3])
    var mpinId = "7b22696174223a313631373237323435332c22757365724944223a22676c6f62616c406578616d706c652e636f6d222c22634944223a2236636134636133622d623663342d343262332d386536372d336432653038616532643765222c2273616c74223a226d30756558414b4162566234425756742b5461745a51222c2276223a352c2273636f7065223a5b2261757468225d2c22647461223a5b5d2c227674223a227076227d"
    let hashOfMpinId = "d3ddd84f90ff4497df43534e0ab0813f71838f5ea92ba98705a84a0d6f593c8d"
    var randomString = NSUUID().uuidString
    var dtas = "WyJEVEEgTm9kZSIsIkRUQSBOb2RlIl0="
    let logger = DefaultLogger(level: .none)

    override func setUpWithError() throws {
        crypto = RegistratorTests.mockCrypto()
        crypto.clientTokenData = clientToken
        userId = NSUUID().uuidString
        activationToken = UUID().uuidString
        dtas = "WyJEVEEgTm9kZSIsIkRUQSBOb2RlIl0="
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
        let clientToken = clientToken
        let mpinId = mpinId
        let hashOfMpinId = hashOfMpinId
        let dtas = dtas

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

        mpinId = "7b22696174223a313632313431373839312c22757365724944223a22383631303732393532222c22634944223a2261623938653665382d326133652d346438632d623831322d323636306433633337373433222c2273616c74223a22486f7063634d7a6a794b53705279616d535333316351222c2276223a352c2273636f7065223a5b2261757468225d2c22647461223a5b5d2c227674223a227076227d"

        dtas = "WyJEVEEgTm9kZSBPdmVycmlkZSIsIkRUQSBOb2RlIE92ZXJyaWRlIl0="
        let secondDtasCopy = dtas

        let mpinIdUpdatedCopy = mpinId
        mockAPI = createMockAPI()

        mockAPI.taSharesResponsesManager.taShare1Response = TAShareResponse(node: "DTA Node Override", share: randomString)
        mockAPI.taSharesResponsesManager.taShare2Response = TAShareResponse(node: "DTA Node Override", share: randomString)

        let newToken = Data([3, 4, 5])
        crypto = RegistratorTests.mockCrypto()
        crypto.signingClientToken = newToken

        let expectation1 = XCTestExpectation(description: "Cannot create Registrator.")
        try register(completionHandler: { user, error in
            do {
                let user = try XCTUnwrap(user)

                XCTAssertEqual(user.userId, userId)
                XCTAssertEqual(user.dtas, secondDtasCopy)
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
                                             crypto: MockCrypto(),
                                             logger: logger,
                                             deviceTagManager: DeviceTagManager(logger: logger),
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
                                             crypto: MockCrypto(),
                                             logger: logger,
                                             deviceTagManager: DeviceTagManager(logger: logger),
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
                                             crypto: MockCrypto(),
                                             logger: logger,
                                             deviceTagManager: DeviceTagManager(logger: logger),
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
                                             crypto: MockCrypto(),
                                             logger: logger,
                                             deviceTagManager: DeviceTagManager(logger: logger),
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

    func testRegistratorEmptyDesginatedTAs() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        mockAPI.registrationResponse?.designatedTAs = []
        mockAPI.registrationError = nil

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorErrorOnFirstTAShareRequest() throws {
        let cause = TestJsonMalformedError.fail
        let desiredError = RegistrationError.registrationFail(cause)

        mockAPI.taSharesResponsesManager.taShare1Error = TestJsonMalformedError.fail
        mockAPI.taSharesResponsesManager.taShare1Response = nil
        mockAPI.taSharesResponsesManager.taShare1ResultCall = .failed

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorNilResponseOnFirstTAShareRequest() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        mockAPI.taSharesResponsesManager.taShare1Error = nil
        mockAPI.taSharesResponsesManager.taShare1Response = nil
        mockAPI.taSharesResponsesManager.taShare1ResultCall = .failed

        try register(completionHandler: { user, error in
            XCTAssertNil(user)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testRegistratorErrorOnSecondTAShareRequest() throws {
        let cause = TestJsonMalformedError.fail
        let desiredError = RegistrationError.registrationFail(cause)

        mockAPI.taSharesResponsesManager.taShare2Error = TestJsonMalformedError.fail
        mockAPI.taSharesResponsesManager.taShare2Response = nil
        mockAPI.taSharesResponsesManager.taShare2ResultCall = .failed

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

    func testRegistratorErrorOneDesignatedTA() throws {
        let desiredError = RegistrationError.registrationFail(nil)

        let taURL = try XCTUnwrap(URL(string: "https://example.com"))
        mockAPI.registrationResponse?.designatedTAs = [
            DesignatedTA(url: taURL, token: randomString)
        ]

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
            deviceName: randomString,
            api: mockAPI,
            userStorage: storage,
            projectId: projectId,
            crypto: crypto,
            logger: logger,
            deviceTagManager: DeviceTagManager(logger: logger),
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

        let registrationResponse2 = RegistrationResponse(
            mpinId: mpinId,
            projectId: projectId,
            designatedTAs: [
                DesignatedTA(url: URL(string: "https://www.example1.com")!, token: UUID().uuidString),
                DesignatedTA(url: URL(string: "https://www.example2.com")!, token: UUID().uuidString)
            ]
        )

        var mockAPI = MockAPI()
        mockAPI.registrationResponse = registrationResponse2

        mockAPI.taSharesResponsesManager.taShare1ResultCall = .success
        mockAPI.taSharesResponsesManager.taShare1Error = nil
        mockAPI.taSharesResponsesManager.taShare1Response = TAShareResponse(node: "DTA Node", share: randomString)

        mockAPI.taSharesResponsesManager.taShare2ResultCall = .success
        mockAPI.taSharesResponsesManager.taShare2Error = nil
        mockAPI.taSharesResponsesManager.taShare2Response = TAShareResponse(node: "DTA Node", share: randomString)

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
