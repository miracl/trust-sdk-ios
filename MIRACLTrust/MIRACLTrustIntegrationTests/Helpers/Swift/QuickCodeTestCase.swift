@testable import MIRACLTrust
import XCTest

class QuickCodeTestCase: XCTestCase {
    var authenticationPinCode: String? = ""

    func generateQuickCode(user: User) async -> (QuickCode?, Error?) {
        let pinCode = authenticationPinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        return await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().generateQuickCode(
                user: user,
                didRequestPinHandler: pinHandler,
                completionHandler: { quickCode, error in
                    continuation.resume(returning: (quickCode, error))
                }
            )
        }
    }
}
