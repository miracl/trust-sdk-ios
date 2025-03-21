@testable import MIRACLTrust
import XCTest

class QRAuthenticationTestCase {
    var pinCode: String? = ""

    func authenticateUser(user: User, qrCode: String) -> (Bool, Error?) {
        let pinCode = pinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        let waitForAuthentication = XCTestExpectation(description: "wait for Authentication")
        nonisolated(unsafe) var isAuthenticated = false
        nonisolated(unsafe) var authenticationError: Error?

        MIRACLTrust.getInstance().authenticateWithQRCode(
            user: user,
            qrCode: qrCode,
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
