import MIRACLTrust
import XCTest

class UniversalLinkAuthenticationTestCase {
    var pinCode: String? = ""

    func authenticateUser(user: User, universalLinkURL: URL) -> (Bool, Error?) {
        let pinCode = pinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        let waitForAuthentication = XCTestExpectation(description: "wait for Authentication")
        nonisolated(unsafe) var isAuthenticated = false
        nonisolated(unsafe) var authenticationError: Error?

        MIRACLTrust
            .getInstance()
            .authenticateWithUniversalLinkURL(
                user: user,
                universalLinkURL: universalLinkURL,
                didRequestPinHandler: pinHandler
            ) { isAuthenticatedResult, error in
                isAuthenticated = isAuthenticatedResult
                authenticationError = error
                waitForAuthentication.fulfill()
            }

        let waitResult = XCTWaiter.wait(for: [waitForAuthentication], timeout: operationTimeout)
        if waitResult != .completed {
            XCTFail("Failed expectation")
        }

        return (isAuthenticated, authenticationError)
    }
}
