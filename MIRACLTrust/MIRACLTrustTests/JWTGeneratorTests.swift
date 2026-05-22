@testable import MIRACLTrust
import XCTest

class JWTGeneratorTests: XCTestCase {
    var user = createValidUser()

    var api = MockAPI()
    var authenticator: MockAuthenticator?
    var responseCode = NSUUID().uuidString
    var storage: UserStorage = MockUserStorage()

    var didRequestPinHandler: PinRequestHandler = { pinHandler in
        let pinCode = Int.random(in: 1000 ..< 9999)
        pinHandler(String(pinCode))
    }

    override func setUpWithError() throws {
        responseCode = NSUUID().uuidString
        storage = MockUserStorage()

        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString,
                projectURL: projectURL
            )
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: configuration)

        try MIRACLTrust.getInstance().userStorage.add(user: user.toUserDTO())
        authenticator = try mockAuthenticator()
    }

    func testSuccessfulJWTGeneration() {
        let responseCode = responseCode
        testJWTGenerator { code, error in
            XCTAssertEqual(code, responseCode)
            XCTAssertNil(error)
        }
    }

    func testFailedJWTGenerationShorterPin() {
        authenticator = nil

        didRequestPinHandler = { pinHandler in
            pinHandler("123")
        }

        testJWTGenerator { code, error in
            XCTAssertNil(code)
            assertError(current: error, expected: AuthenticationError.invalidPin)
        }
    }

    func testFailedJWTGenerationLongerPin() {
        authenticator = nil

        didRequestPinHandler = { pinHandler in
            pinHandler("12345678")
        }

        testJWTGenerator { code, error in
            XCTAssertNil(code)
            assertError(current: error, expected: AuthenticationError.invalidPin)
        }
    }

    func testFailedJWTGenerationEmptyIdentity() {
        authenticator = nil
        user = JWTGeneratorTests.createValidUser(mpinId: Data(), token: Data())

        testJWTGenerator { code, error in
            XCTAssertNil(code)
            assertError(current: error, expected: AuthenticationError.invalidUserData)
        }
    }

    func testFailedJWTGenerationInvalidCodeResponse() {
        authenticator?.response = nil

        testJWTGenerator { code, error in
            XCTAssertNil(code)
            assertError(current: error, expected: AuthenticationError.authenticationFail(nil))
        }
    }

    /// Helper functions
    private func testJWTGenerator(
        testCompletionHandler: @escaping JWTCompletionHandler
    ) {
        let expectation = XCTestExpectation(description: "Wait for JWT.")
        let logger = DefaultLogger(level: .none)

        var generator = JWTGenerator(
            user: user,
            miraclAPI: api,
            deviceName: UUID().uuidString,
            userStorage: storage,
            crypto: MockCrypto(),
            logger: logger,
            deviceTagManager: DeviceTagManager(logger: logger),
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { code, error in
                testCompletionHandler(code, error)
                expectation.fulfill()
            }
        )
        generator.authenticator = authenticator
        generator.generate()

        wait(for: [expectation], timeout: 20.0)
    }

    class func createValidUser(
        mpinId: Data = Data([1, 2, 3]),
        token: Data = Data([3, 2, 1])
    ) -> User {
        User(
            userId: "example@example.com",
            projectId: UUID().uuidString,
            revoked: false,
            pinLength: 4,
            mpinId: mpinId,
            token: token,
            dtas: "dtas",
            publicKey: nil
        )
    }

    func mockAuthenticator() throws -> MockAuthenticator {
        var authenticateResponse = AuthenticateResponse()
        authenticateResponse.jwt = responseCode

        var mockAuthenticator = MockAuthenticator(completionHandler: { _, _ in })
        mockAuthenticator.error = nil
        mockAuthenticator.response = authenticateResponse

        return mockAuthenticator
    }
}
