@testable import MIRACLTrust
import XCTest

class RegistrationTestCase {
    var pinCode: String? = ""

    func registerUser(
        userId: String,
        activationToken: String
    ) async -> (User?, Error?) {
        let pinCode = pinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        return await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().register(for: userId, activationToken: activationToken, didRequestPinHandler: pinHandler) { user, error in
                continuation.resume(returning: (user, error))
            }
        }
    }
}
