@testable import MIRACLTrust
import XCTest

class SigningSessionAborterTestCase: XCTest {
    func abortSigningSession(signingSessionDetails: SigningSessionDetails) -> (Bool, Error?) {
        let abortSigningSessionExpectation = XCTestExpectation(
            description: "Get Signing Session Details from qrCode"
        )

        nonisolated(unsafe) var isAborted = false
        nonisolated(unsafe) var returnedError: Error?

        MIRACLTrust.getInstance().abortSigningSession(
            signingSessionDetails: signingSessionDetails
        ) { aborted, error in
            isAborted = aborted
            returnedError = error
            abortSigningSessionExpectation.fulfill()
        }

        _ = XCTWaiter.wait(for: [abortSigningSessionExpectation], timeout: operationTimeout)
        return (isAborted, returnedError)
    }
}
