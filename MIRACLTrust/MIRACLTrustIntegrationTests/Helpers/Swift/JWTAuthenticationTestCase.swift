@testable import MIRACLTrust
import XCTest

class JWTAuthenticationTestCase: XCTestCase {
    var pinCode: String? = ""

    func generateJWT(
        user: User
    ) async -> (String?, Error?) {
        let pinCode = pinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        return await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().authenticate(
                user: user,
                didRequestPinHandler: pinHandler,
                completionHandler: { jwt, error in
                    continuation.resume(returning: (jwt, error))
                }
            )
        }
    }
}
