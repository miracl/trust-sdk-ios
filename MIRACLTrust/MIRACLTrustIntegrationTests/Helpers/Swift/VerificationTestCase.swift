@testable import MIRACLTrust
import XCTest

class VerificationTestCase {
    func sendVerificationEmail(
        userId: String,
        authenticationSessionDetails: AuthenticationSessionDetails? = nil
    ) -> (VerificationResponse?, Error?) {
        let waitForVerification = XCTestExpectation(description: "wait for verification")

        nonisolated(unsafe) var verificationResponse: VerificationResponse?
        nonisolated(unsafe) var returnedError: Error?

        MIRACLTrust.getInstance().sendVerificationEmail(
            userId: userId,
            authenticationSessionDetails: authenticationSessionDetails
        ) { result, error in
            verificationResponse = result
            returnedError = error
            waitForVerification.fulfill()
        }

        let waitResult = XCTWaiter.wait(for: [waitForVerification], timeout: operationTimeout)
        if waitResult != .completed {
            XCTFail("Failed expectation")
        }

        return (verificationResponse, returnedError)
    }
}
