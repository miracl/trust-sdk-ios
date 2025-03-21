@testable import MIRACLTrust
import XCTest

class AbortSessionTests: XCTestCase {
    var accessId = ""
    var userId = ""
    var api = MockAPI()

    override func setUpWithError() throws {
        accessId = "b227d0850d4280b98c5124a14aec84bf"
        userId = "global@example.com"

        api.sessionAborterError = nil
        api.sessionAborterResultCall = .success

        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString
            )
            .build()
        try MIRACLTrust.configure(with: configuration)
    }

    func testAbortSession() {
        abortSession { isAborted, error in
            XCTAssertTrue(isAborted)
            XCTAssertNil(error)
        }
    }

    func testAbortSessionEmptyAccessId() {
        accessId = ""
        XCTAssertThrowsError(try AuthenticationSessionAborter(
            accessId: accessId,
            completionHandler: { _, _ in }
        ), "Abort session with empty userId") { error in
            assertError(current: error, expected: AuthenticationSessionError.invalidAuthenticationSessionDetails)
        }
    }

    func testAbortSessionWhitespaceAccessId() {
        accessId = "\n     "
        XCTAssertThrowsError(try AuthenticationSessionAborter(
            accessId: accessId,
            completionHandler: { _, _ in }
        ), "Abort session with empty userId") { error in
            assertError(current: error, expected: AuthenticationSessionError.invalidAuthenticationSessionDetails)
        }
    }

    func testAbortSessionNilResponse() {
        api.sessionAborterResultCall = .failed
        api.sessionAborterError = nil
        api.sessionDetailsResponse = nil

        abortSession { isAborted, error in
            XCTAssertFalse(isAborted)
            assertError(current: error, expected: AuthenticationSessionError.abortSessionFail(nil))
        }
    }

    func testAbortSessionErrorServerResponse() {
        let cause = APIError.apiServerError(statusCode: 500, message: nil, requestURL: nil)
        let desiredError = AuthenticationSessionError.abortSessionFail(cause)

        api.sessionAborterResultCall = .failed
        api.sessionAborterError = desiredError
        api.sessionAborterError = cause
        api.sessionDetailsResponse = nil

        abortSession { isAborted, error in
            XCTAssertFalse(isAborted)
            assertError(current: error, expected: desiredError)
        }
    }

    // MARK: Private

    private func abortSession(
        completionHandler: @escaping AuthenticationSessionAborterCompletionHandler
    ) {
        do {
            let expectation = XCTestExpectation(description: "Wait for session abort")

            let aborter = try AuthenticationSessionAborter(
                accessId: accessId,
                miraclAPI: api
            ) { isAborted, error in
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
}
