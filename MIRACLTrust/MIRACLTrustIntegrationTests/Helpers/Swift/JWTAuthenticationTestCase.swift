@testable import MIRACLTrust
import XCTest

class JWTAuthenticationTestCase: XCTestCase {
    var pinCode: String? = ""

    func generateJWT(
        user: User
    ) -> (String?, Error?) {
        let waitForJWT = XCTestExpectation(description: "wait for JWT generation")

        nonisolated(unsafe) var returnedJWT: String?
        nonisolated(unsafe) var returnedError: Error?

        let pinCode = pinCode

        MIRACLTrust.getInstance().authenticate(
            user: user,
            didRequestPinHandler: { pinHandler in
                pinHandler(pinCode)
            }, completionHandler: { jwt, error in
                returnedJWT = jwt
                returnedError = error
                waitForJWT.fulfill()
            }
        )

        let result = XCTWaiter.wait(for: [waitForJWT], timeout: operationTimeout)
        if result != .completed {
            XCTFail("Something wrong happened")
        }

        return (returnedJWT, returnedError)
    }
}
