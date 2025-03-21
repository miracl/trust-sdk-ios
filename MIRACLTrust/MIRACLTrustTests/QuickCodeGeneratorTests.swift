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
                projectId: NSUUID().uuidString
            )
            .userStorage(userStorage: storage)
            .build()

        user = createUser(userId: userId, projectId: projectId)
        try MIRACLTrust.configure(with: configuration)
        try storage.add(user: XCTUnwrap(user))

        authenticator = mockAuthenticator()
    }

    func testQuickCodeGenerator() throws {
        let quickCodeString = quickCodeString
        let ttlSeconds = ttlSeconds
        let expireTime = expireTime

        try testQuickCodeGenerator(testCompletionHandler: { quickCode, error in
            XCTAssertNil(error)

            do {
                let quickCode = try XCTUnwrap(quickCode)
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
        authenticator?.error = AuthenticationError.invalidUserData

        try testQuickCodeGenerator { quickCode, error in
            XCTAssertNil(quickCode)
            assertError(current: error, expected: expectedError)
        }
    }

    func testForEmptyAuthenticateResponse() throws {
        let expectedError = QuickCodeError.generationFail(nil)
        authenticator?.response = nil

        try testQuickCodeGenerator { quickCode, error in
            XCTAssertNil(quickCode)
            assertError(current: error, expected: expectedError)
        }
    }

    func testForNilJWT() throws {
        let expectedError = QuickCodeError.generationFail(nil)
        authenticator?.response?.jwt = nil

        try testQuickCodeGenerator { quickCode, error in
            XCTAssertNil(quickCode)
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

        try testQuickCodeGenerator { quickCode, error in
            XCTAssertNil(quickCode)
            assertError(current: error, expected: expectedError)
        }
    }

    func testForVerificationQuickCodeErrorWithoutWrappedError() throws {
        let expectedError = QuickCodeError.generationFail(
            nil
        )
        mockAPI.verificationQuickCodeResponse = nil
        mockAPI.verificationQuickCodeError = nil

        try testQuickCodeGenerator { quickCode, error in
            XCTAssertNil(quickCode)
            assertError(current: error, expected: expectedError)
        }
    }

    func testForUnsuccessfulAuthentication() throws {
        let returnedError = AuthenticationError.unsuccessfulAuthentication
        let expectedError = QuickCodeError.unsuccessfulAuthentication

        authenticator?.response = nil
        authenticator?.error = returnedError

        try testQuickCodeGenerator { quickCode, error in
            XCTAssertNil(quickCode)
            assertError(current: error, expected: expectedError)
        }
    }

    func testForRevoked() throws {
        let returnedError = AuthenticationError.revoked
        let expectedError = QuickCodeError.revoked

        authenticator?.response = nil
        authenticator?.error = returnedError

        try testQuickCodeGenerator { quickCode, error in
            XCTAssertNil(quickCode)
            assertError(current: error, expected: expectedError)
        }
    }

    func testForInvalidPin() throws {
        let returnedError = AuthenticationError.invalidPin
        let expectedError = QuickCodeError.invalidPin

        authenticator?.response = nil
        authenticator?.error = returnedError

        try testQuickCodeGenerator { quickCode, error in
            XCTAssertNil(quickCode)
            assertError(current: error, expected: expectedError)
        }
    }

    func testForCancelledPin() throws {
        let returnedError = AuthenticationError.pinCancelled
        let expectedError = QuickCodeError.pinCancelled

        authenticator?.response = nil
        authenticator?.error = returnedError

        try testQuickCodeGenerator { quickCode, error in
            XCTAssertNil(quickCode)
            assertError(current: error, expected: expectedError)
        }
    }

    func testForLimitedQuickCodeGeneration() throws {
        let expectedError = QuickCodeError.limitedQuickCodeGeneration

        authenticator?.response = nil
        authenticator?.error = AuthenticationError.authenticationFail(
            apiClientError(with: LIMITED_QUICKCODE_GENERATION)
        )

        try testQuickCodeGenerator { quickCode, error in
            XCTAssertNil(quickCode)
            assertError(current: error, expected: expectedError)
        }
    }

    func testForUnknownCode() throws {
        let returnedError = AuthenticationError.authenticationFail(
            apiClientError(with: "EXAMPLE_CODE"))
        authenticator?.response = nil
        authenticator?.error = returnedError

        let expectedError = QuickCodeError.generationFail(returnedError)

        try testQuickCodeGenerator { quickCode, error in
            XCTAssertNil(quickCode)
            assertError(current: error, expected: expectedError)
        }
    }

    // MARK: Private

    private func testQuickCodeGenerator(testCompletionHandler: @escaping QuickCodeCompletionHandler) throws {
        let testExpectation = XCTestExpectation(description: "Quick Code Unit Tests")
        var quickCodeGenerator = try QuickCodeGenerator(
            user: XCTUnwrap(user),
            api: mockAPI,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { quickCode, error in
                testCompletionHandler(quickCode, error)
                testExpectation.fulfill()
            }
        )
        quickCodeGenerator.authenticator = authenticator
        quickCodeGenerator.generate()
        wait(for: [testExpectation], timeout: 20.0)
    }

    private func mockAuthenticator() -> MockAuthenticator {
        var mockAuthenticator = MockAuthenticator(completionHandler: { _, _ in })
        mockAuthenticator.error = nil
        mockAuthenticator.response = authenticateResponse

        return mockAuthenticator
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
            clientErrorData: clientErrorData,
            requestId: "",
            message: nil,
            requestURL: nil
        )
    }
}
