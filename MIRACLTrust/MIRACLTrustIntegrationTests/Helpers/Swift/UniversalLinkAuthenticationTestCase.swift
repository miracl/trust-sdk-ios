import MIRACLTrust
import XCTest

class UniversalLinkAuthenticationTestCase {
    var pinCode: String? = ""

    func authenticateUser(user: User, universalLinkURL: URL) async -> (Bool, Error?) {
        let pinCode = pinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        return await withCheckedContinuation { continuation in
            MIRACLTrust
                .getInstance()
                .authenticateWithUniversalLinkURL(
                    user: user,
                    universalLinkURL: universalLinkURL,
                    didRequestPinHandler: pinHandler
                ) { isAuthenticatedResult, error in
                    continuation.resume(returning: (isAuthenticatedResult, error))
                }
        }
    }
}
