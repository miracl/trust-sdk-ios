@testable import MIRACLTrust
import XCTest

final class SigningSessionAborterTest: XCTestCase {
    var sessionId: String = ""
    var mockAPI = MockAPI()

    override func setUpWithError() throws {
        sessionId = UUID().uuidString

        mockAPI.signingSessionAborterError = nil
        mockAPI.signingSessionAborterResultCall = .success
        mockAPI.signingSessionAborterResponse = nil
    }

    func testAbortSigningSession() throws {
        try abortSigningSession { aborted, error in
            XCTAssertTrue(aborted)
            XCTAssertNil(error)
        }
    }

    func testAbortSigningSessionForEmptySessionId() {
        sessionId = "  "
        let expectedError = SigningSessionError.invalidSigningSessionDetails

        XCTAssertThrowsError(
            try abortSigningSession { aborted, error in
                XCTAssertTrue(aborted)
                XCTAssertNil(error)
            }
        ) { error in
            assertError(current: error, expected: expectedError)
        }
    }

    func testAbortSigningSessionForInvalidSessionError() throws {
        let expectedError = SigningSessionError.invalidSigningSession

        mockAPI.signingSessionAborterError = apiClientError(with: INVALID_REQUEST_PARAMETERS, context: ["params": "id"])
        mockAPI.signingSessionAborterResultCall = .failed

        try abortSigningSession { aborted, error in
            XCTAssertFalse(aborted)
            assertError(current: error, expected: expectedError)
        }
    }

    func testAbortSigningSessionForUnexpectedError() throws {
        let wrappedError = APIError.apiServerError(
            statusCode: 500,
            message: "",
            requestURL: nil
        )
        let expectedError = SigningSessionError.abortSigningSessionFail(wrappedError)

        mockAPI.signingSessionAborterError = wrappedError
        mockAPI.signingSessionAborterResultCall = .failed

        try abortSigningSession { aborted, error in
            XCTAssertFalse(aborted)
            assertError(current: error, expected: expectedError)
        }
    }

    // MARK: Private

    private func abortSigningSession(
        completionHandler: @escaping SigningSessionAborterCompletionHandler
    ) throws {
        let testExpectation = XCTestExpectation(description: "Wait for session abort")
        let sessionAborter = try SigningSessionAborter(sessionId: sessionId, miraclAPI: mockAPI) { aborted, error in

            completionHandler(aborted, error)
            testExpectation.fulfill()
        }
        sessionAborter.abort()

        let waitResult = XCTWaiter.wait(for: [testExpectation], timeout: 10.0)
        if waitResult != .completed {
            XCTFail("Failed abort signing session expectation")
        }
    }

    private func apiClientError(with code: String, context: [String: String]? = nil) -> APIError {
        let clientErrorData = ClientErrorData(
            code: code,
            info: "",
            context: context
        )

        return APIError.apiClientError(clientErrorData: clientErrorData, requestId: "", message: nil, requestURL: nil)
    }
}
