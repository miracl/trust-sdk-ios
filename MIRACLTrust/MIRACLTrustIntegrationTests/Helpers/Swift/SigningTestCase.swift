@testable import MIRACLTrust
import XCTest

class SigningTestCase {
    var signingPinCode = ""

    func signMessage(message: Data, user: User) async -> (SigningResult?, Error?) {
        let pinCode = signingPinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        return await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().sign(
                message: message,
                user: user,
                didRequestSigningPinHandler: pinHandler,
                completionHandler: { signature, error in
                    continuation.resume(returning: (signature, error))
                }
            )
        }
    }

    func signMessage(crossDeviceSession: CrossDeviceSession, user: User) async -> (Bool, Error?) {
        let pinCode = signingPinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        return await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance()._sign(
                crossDeviceSession: crossDeviceSession,
                user: user,
                didRequestSigningPinHandler: pinHandler
            ) { isSigned, error in
                continuation.resume(returning: (isSigned, error))
            }
        }
    }
}
