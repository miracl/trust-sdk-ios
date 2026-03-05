import MIRACLTrust
import XCTest

class GetCrossDeviceSessionTestCase {
    func getCrossDeviceSession(qrCode: String) async -> (CrossDeviceSession?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance()._getCrossDeviceSessionFromQRCode(qrCode: qrCode) { session, error in
                continuation.resume(returning: (session, error))
            }
        }
    }

    func getCrossDeviceSession(universalLinkURL: URL) async -> (CrossDeviceSession?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance()._getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL: universalLinkURL) { session, error in
                continuation.resume(returning: (session, error))
            }
        }
    }

    func getCrossDeviceSession(pushNotificationPayload: [AnyHashable: Any]) async -> (CrossDeviceSession?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance()._getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload: pushNotificationPayload) { session, error in
                continuation.resume(returning: (session, error))
            }
        }
    }
}
