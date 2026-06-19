import MIRACLTrust
import XCTest

class GetCrossDeviceSessionTestCase {
    func getCrossDeviceSession(qrCode: String) async -> (CrossDeviceSession?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().getCrossDeviceSessionFromQRCode(qrCode: qrCode) { session, error in
                continuation.resume(returning: (session, error))
            }
        }
    }

    func getCrossDeviceSession(universalLinkURL: URL) async -> (CrossDeviceSession?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL: universalLinkURL) { session, error in
                continuation.resume(returning: (session, error))
            }
        }
    }

    func getCrossDeviceSession(pushNotificationPayload: [AnyHashable: Any]) async -> (CrossDeviceSession?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload: pushNotificationPayload) { session, error in
                continuation.resume(returning: (session, error))
            }
        }
    }
}
