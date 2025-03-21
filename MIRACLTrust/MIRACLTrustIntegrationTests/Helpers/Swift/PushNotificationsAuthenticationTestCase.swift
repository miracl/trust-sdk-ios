import MIRACLTrust
import XCTest

class PushNotificationsAuthenticationTestCase {
    var pinCode: String? = ""

    func authenticateUser(user _: User, pushPayload: [AnyHashable: Any]) -> (Bool, Error?) {
        let pinCode = pinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        let waitForAuthentication = XCTestExpectation(description: "wait for Authentication")
        nonisolated(unsafe) var isAuthenticated = false
        nonisolated(unsafe) var authenticationError: Error?

        MIRACLTrust
            .getInstance()
            .authenticateWithPushNotificationPayload(
                payload: pushPayload,
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
