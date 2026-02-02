import MIRACLTrust

struct CrossDeviceSessionCase {
    func getCrossDeviceSessionForQRCode(
        qrCode: String
    ) async throws -> CrossDeviceSession {
        try await withCheckedThrowingContinuation { continuation in
            MIRACLTrust.getInstance()._getCrossDeviceSessionFromQRCode(qrCode: qrCode) { cdSession, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let cdSession {
                    continuation.resume(returning: cdSession)
                }
            }
        }
    }

    func getCrossDeviceSessionForUniversalLinkURL(
        universalLinkURL: URL
    ) async throws -> CrossDeviceSession {
        try await withCheckedThrowingContinuation { continuation in
            MIRACLTrust.getInstance()._getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL: universalLinkURL) { cdSession, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let cdSession {
                    continuation.resume(returning: cdSession)
                }
            }
        }
    }

    func getCrossDeviceSessionForPushNotificationPayload(
        payload: [AnyHashable: Any]
    ) async throws -> CrossDeviceSession {
        try await withCheckedThrowingContinuation { continuation in
            MIRACLTrust.getInstance()._getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload: payload) { cdSession, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let cdSession {
                    continuation.resume(returning: cdSession)
                }
            }
        }
    }
}
