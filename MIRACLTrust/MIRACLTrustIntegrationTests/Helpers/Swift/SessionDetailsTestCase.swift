@testable import MIRACLTrust

class SessionDetailsTestCase {
    func getSessionDetails(qrCode: String) async -> (AuthenticationSessionDetails?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust
                .getInstance()
                .getAuthenticationSessionDetailsFromQRCode(
                    qrCode: qrCode
                ) { details, error in
                    continuation.resume(returning: (details, error))
                }
        }
    }

    func getSessionDetails(universalLinkURL: URL) async -> (SessionDetails?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust
                .getInstance()
                .getAuthenticationSessionDetailsFromUniversalLinkURL(
                    universalLinkURL: universalLinkURL
                ) { details, error in
                    continuation.resume(returning: (details, error))
                }
        }
    }

    func getSessionDetails(payload: [AnyHashable: Any]) async -> (SessionDetails?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust
                .getInstance()
                .getAuthenticationSessionDetailsFromPushNotificationPayload(
                    pushNotificationPayload: payload
                ) { details, error in
                    continuation.resume(returning: (details, error))
                }
        }
    }
}
