import MIRACLTrust
import XCTest

class PushNotificationsAuthenticationTestCase {
    var pinCode: String? = ""

    func authenticateUser(user _: User, pushPayload: [AnyHashable: Any]) async -> (Bool, Error?) {
        let pinCode = pinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        return await withCheckedContinuation { continuation in
            MIRACLTrust
                .getInstance()
                .authenticateWithPushNotificationPayload(
                    payload: pushPayload,
                    didRequestPinHandler: pinHandler
                ) { isAuthenticatedResult, error in
                    continuation.resume(returning: (isAuthenticatedResult, error))
                }
        }
    }
}
