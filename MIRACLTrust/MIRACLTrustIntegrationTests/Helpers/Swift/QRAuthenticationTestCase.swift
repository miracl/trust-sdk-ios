@testable import MIRACLTrust
import XCTest

class QRAuthenticationTestCase {
    var pinCode: String? = ""

    func authenticateUser(user: User, qrCode: String) async -> (Bool, Error?) {
        let pinCode = pinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        return await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().authenticateWithQRCode(
                user: user,
                qrCode: qrCode,
                didRequestPinHandler: pinHandler
            ) { isAuthenticatedResult, error in
                continuation.resume(returning: (isAuthenticatedResult, error))
            }
        }
    }
}
