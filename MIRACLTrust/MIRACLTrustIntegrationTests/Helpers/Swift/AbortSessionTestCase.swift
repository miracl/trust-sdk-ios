@testable import MIRACLTrust
import XCTest

class AbortSessionTestCase: XCTest {
    func abortSession(sessionDetails: AuthenticationSessionDetails) -> (Bool, Error?) {
        let waitForSessionAbort = XCTestExpectation(description: "wait for Session abort")

        nonisolated(unsafe) var isAbortedResult = false
        nonisolated(unsafe) var returnedError: Error?

        MIRACLTrust
            .getInstance()
            .abortAuthenticationSession(
                authenticationSessionDetails: sessionDetails
            ) { isAborted, error in
                isAbortedResult = isAborted
                returnedError = error
                waitForSessionAbort.fulfill()
            }

        let result = XCTWaiter.wait(
            for: [waitForSessionAbort],
            timeout: operationTimeout
        )
        if result != .completed {
            XCTFail("Something wrong happened")
        }

        return (isAbortedResult, returnedError)
    }
}
