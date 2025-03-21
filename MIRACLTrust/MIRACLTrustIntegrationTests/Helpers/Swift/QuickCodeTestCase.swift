@testable import MIRACLTrust
import XCTest

class QuickCodeTestCase: XCTestCase {
    var authenticationPinCode: String? = ""

    func generateQuickCode(user: User) -> (QuickCode?, Error?) {
        let waitForQuickCode = XCTestExpectation(description: "wait for QuickCode")

        nonisolated(unsafe) var returnedQuickCode: QuickCode?
        nonisolated(unsafe) var returnedError: Error?

        let pinCode = authenticationPinCode
        MIRACLTrust.getInstance().generateQuickCode(
            user: user,
            didRequestPinHandler: { pinHandler in
                pinHandler(pinCode)
            }, completionHandler: { quickCode, error in
                returnedQuickCode = quickCode
                returnedError = error

                waitForQuickCode.fulfill()
            }
        )

        let result = XCTWaiter.wait(for: [waitForQuickCode], timeout: operationTimeout)
        if result != .completed {
            XCTFail("Something wrong happened")
        }

        return (returnedQuickCode, returnedError)
    }
}
