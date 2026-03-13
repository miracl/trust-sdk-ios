@testable import MIRACLTrust
import XCTest

final class CrossDeviceSessionAborterTest: XCTestCase {
    var sessionId = ""
    var userId = ""
    var api = MockAPI()

    override func setUpWithError() throws {
        sessionId = "b227d0850d4280b98c5124a14aec84bf"
        userId = "global@example.com"

        api.sessionAborterError = nil
        api.sessionAborterResultCall = .success

        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString,
                projectURL: projectURL
            )
            .build()
        try MIRACLTrust.configure(with: configuration)
    }

    func testAbortSession() {
        abortCrossDeviceSession { isAborted, error in
            XCTAssertTrue(isAborted)
            XCTAssertNil(error)
        }
    }

    func testAbortSessionEmptySessionId() {
        sessionId = ""
        XCTAssertThrowsError(try CrossDeviceSessionAborter(
            sessionId: sessionId,
            miraclAPI: api,
            completionHandler: { _, _ in }
        ), "Abort session with empty sessionId") { error in
            assertError(current: error, expected: CrossDeviceSessionError.invalidCrossDeviceSession)
        }
    }

    func testAbortSessionWhitespaceSessionId() {
        sessionId = "\n     "
        XCTAssertThrowsError(try CrossDeviceSessionAborter(
            sessionId: sessionId,
            miraclAPI: api,
            completionHandler: { _, _ in }
        ), "Abort session with empty sessionId") { error in
            assertError(current: error, expected: CrossDeviceSessionError.invalidCrossDeviceSession)
        }
    }

    func testAbortSessionNilResponse() {
        api.sessionAborterResultCall = .failed
        api.sessionAborterError = nil
        api.sessionDetailsResponse = nil

        abortCrossDeviceSession { isAborted, error in
            XCTAssertFalse(isAborted)
            assertError(current: error, expected: CrossDeviceSessionError.abortCrossDeviceSessionFail(nil))
        }
    }

    func testAbortSessionErrorServerResponse() {
        let cause = APIError.apiServerError(statusCode: 500, message: nil, requestURL: nil)
        let desiredError = CrossDeviceSessionError.abortCrossDeviceSessionFail(cause)

        api.sessionAborterResultCall = .failed
        api.sessionAborterError = desiredError
        api.sessionAborterError = cause
        api.sessionDetailsResponse = nil

        abortCrossDeviceSession { isAborted, error in
            XCTAssertFalse(isAborted)
            assertError(current: error, expected: desiredError)
        }
    }

    func testAbortCrossDeviceSession() {
        let expectedError = CrossDeviceSessionError.invalidCrossDeviceSession

        api.sessionAborterResultCall = .failed
        api.sessionAborterError = apiClientError(
            with: INVALID_REQUEST_PARAMETERS,
            context: ["params": "id"]
        )
        api.sessionAborterResponse = [:]

        abortCrossDeviceSession { isAborted, error in
            XCTAssertFalse(isAborted)
            assertError(current: error, expected: expectedError)
        }
    }

    // MARK: Private

    private func abortCrossDeviceSession(
        completionHandler: @escaping AuthenticationSessionAborterCompletionHandler
    ) {
        do {
            let expectation = XCTestExpectation(description: "Wait for session abort")

            let aborter = try CrossDeviceSessionAborter(sessionId: sessionId, miraclAPI: api) { isAborted, error in
                completionHandler(isAborted, error)
                expectation.fulfill()
            }
            aborter.abort()

            let waitResult = XCTWaiter.wait(for: [expectation], timeout: 10.0)
            if waitResult != .completed {
                XCTFail("Failed expectation")
            }
        } catch {
            XCTFail("Session Cannot be aborted")
        }
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
