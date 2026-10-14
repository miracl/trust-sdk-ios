@testable import MIRACLTrust
import XCTest

class QuickCodeGeneratorTests: XCTestCase {
    var mockAPI = MockAPI()
    var authenticator: MockAuthenticator?
    var authenticateResponse = AuthenticateResponse()
    var quickCodeString = UUID().uuidString
    var expireTime = Date()
    var ttlSeconds = Int.random(in: 1 ... 9999)
    var storage = MockUserStorage()

    let crypto = MockCrypto()
    let deviceName = UUID().uuidString
    let logger = DefaultLogger(level: .none)

    var projectId = UUID().uuidString
    var userId = UUID().uuidString
    var user: User?

    var didRequestPinHandler: PinRequestHandler = { pinHandler in
        let pinCode = Int.random(in: 1000 ..< 9999)
        pinHandler(String(pinCode))
    }

    override func setUpWithError() throws {
        authenticateResponse.jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

        mockAPI.verificationQuickCodeError = nil
        mockAPI.verificationQuickCodeResponse = VerificationQuickCodeResponse(
            code: quickCodeString,
            expireTime: expireTime,
            ttlSeconds: ttlSeconds
        )

        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString,
                projectURL: projectURL
            )
            .userStorage(userStorage: storage)
            .build()

        user = createUser(userId: userId, projectId: projectId)
        let userDTO = try XCTUnwrap(user).toUserDTO()
        try MIRACLTrust.configure(with: configuration)
        try storage.add(user: userDTO)

        authenticator = mockAuthenticator()
    }

    func testQuickCodeGenerator() throws {
        let quickCodeString = quickCodeString
        let ttlSeconds = ttlSeconds
        let expireTime = expireTime

        try testQuickCodeGenerator(testCompletionHandler: { result in
            do {
                let quickCode = try result.get()
                XCTAssertEqual(quickCode.code, quickCodeString)
                XCTAssertEqual(quickCode.ttlSeconds, ttlSeconds)
                XCTAssertEqual(quickCode.expireTime, expireTime)
            } catch {
                XCTFail("Quick Code test failed with error = \(error)")
            }
        })
    }

    func testForAuthenticationIssue() throws {
        let expectedError = QuickCodeError.generationFail(AuthenticationError.invalidUserData)
        authenticator?.result = .failure(AuthenticationError.invalidUserData)

        try testQuickCodeGenerator { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected .failure, but got \(result)")
                return
            }
            assertError(current: error, expected: expectedError)
        }
    }

    func testForNilJWT() throws {
        let expectedError = QuickCodeError.generationFail(nil)

        var authenticationResponse = AuthenticateResponse()
        authenticationResponse.jwt = nil
        authenticator?.result = .success(authenticationResponse)

        try testQuickCodeGenerator { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected .failure, but got \(result)")
                return
            }
            assertError(current: error, expected: expectedError)
        }
    }

    func testForVerificationQuickCodeError() throws {
        let returnedError = APIError.executionError("", nil)
        let expectedError = QuickCodeError.generationFail(
            returnedError
        )
        mockAPI.verificationQuickCodeResponse = nil
        mockAPI.verificationQuickCodeError = returnedError

        try testQuickCodeGenerator { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected .failure, but got \(result)")
                return
            }
            assertError(current: error, expected: expectedError)
        }
    }

    func testForVerificationQuickCodeErrorWithoutWrappedError() throws {
        let expectedError = QuickCodeError.generationFail(
            nil
        )
        mockAPI.verificationQuickCodeResponse = nil
        mockAPI.verificationQuickCodeError = nil

        try testQuickCodeGenerator { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected .failure, but got \(result)")
                return
            }
            assertError(current: error, expected: expectedError)
        }
    }

    func testForUnsuccessfulAuthentication() throws {
        let returnedError = AuthenticationError.unsuccessfulAuthentication
        let expectedError = QuickCodeError.unsuccessfulAuthentication

        authenticator?.result = .failure(returnedError)

        try testQuickCodeGenerator { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected .failure, but got \(result)")
                return
            }
            assertError(current: error, expected: expectedError)
        }
    }

    func testForRevoked() throws {
        let returnedError = AuthenticationError.revoked
        let expectedError = QuickCodeError.revoked

        authenticator?.result = .failure(returnedError)

        try testQuickCodeGenerator { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected .failure, but got \(result)")
                return
            }
            assertError(current: error, expected: expectedError)
        }
    }

    func testForInvalidPin() throws {
        let returnedError = AuthenticationError.invalidPin
        let expectedError = QuickCodeError.invalidPin

        authenticator?.result = .failure(returnedError)

        try testQuickCodeGenerator { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected .failure, but got \(result)")
                return
            }
            assertError(current: error, expected: expectedError)
        }
    }

    func testForCancelledPin() throws {
        let returnedError = AuthenticationError.pinCancelled
        let expectedError = QuickCodeError.pinCancelled

        authenticator?.result = .failure(returnedError)

        try testQuickCodeGenerator { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected .failure, but got \(result)")
                return
            }
            assertError(current: error, expected: expectedError)
        }
    }

    func testForUnknownCode() throws {
        let returnedError = AuthenticationError.authenticationFail(
            apiClientError(with: "EXAMPLE_CODE")
        )
        authenticator?.result = .failure(returnedError)

        let expectedError = QuickCodeError.generationFail(returnedError)

        try testQuickCodeGenerator { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected .failure, but got \(result)")
                return
            }
            assertError(current: error, expected: expectedError)
        }
    }

    // MARK: Private

    private func testQuickCodeGenerator(testCompletionHandler: @escaping QuickCodeResultCompletionHandler) throws {
        let testExpectation = XCTestExpectation(description: "Quick Code Unit Tests")
        var quickCodeGenerator = try QuickCodeGenerator(
            user: XCTUnwrap(user),
            api: mockAPI,
            deviceName: deviceName,
            storage: storage,
            crypto: crypto,
            logger: logger,
            deviceTagManager: DeviceTagManager(logger: logger),
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { result in
                testCompletionHandler(result)
                testExpectation.fulfill()
            }
        )
        quickCodeGenerator.authenticator = authenticator
        quickCodeGenerator.generate()
        wait(for: [testExpectation], timeout: 20.0)
    }

    private func mockAuthenticator() -> MockAuthenticator {
        MockAuthenticator(completionHandler: { _ in }, result: .success(authenticateResponse))
    }

    private func createUser(
        userId: String = UUID().uuidString,
        projectId: String = UUID().uuidString
    ) -> User {
        User(
            userId: userId,
            projectId: projectId,
            revoked: false,
            pinLength: 4,
            mpinId: Data([1, 2, 3]),
            token: Data([3, 2, 1]),
            dtas: "dtas",
            publicKey: nil
        )
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
