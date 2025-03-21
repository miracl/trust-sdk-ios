@testable import MIRACLTrust
import XCTest

class RegistrationTestCase {
    var pinCode: String? = ""

    func registerUser(
        userId: String,
        activationToken: String
    ) -> (User?, Error?) {
        let pinCode = pinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        let waitForUser = XCTestExpectation(description: "wait for User")
        nonisolated(unsafe) var returnedUser: User?
        nonisolated(unsafe) var returnedError: Error?

        MIRACLTrust.getInstance().register(
            for: userId,
            activationToken: activationToken,
            didRequestPinHandler: pinHandler
        ) { user, error in
            returnedUser = user
            returnedError = error
            waitForUser.fulfill()
        }
        let waitResult = XCTWaiter.wait(for: [waitForUser], timeout: 30)
        if waitResult != .completed {
            XCTFail("Failed expectation")
        }
        return (returnedUser, returnedError)
    }
}
