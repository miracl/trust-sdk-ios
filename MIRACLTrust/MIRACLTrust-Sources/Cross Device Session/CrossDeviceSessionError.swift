import Foundation

/// An enumeration that describes issues with the cross-device session management.
public enum CrossDeviceSessionError: Error, DefaultLocalizedError {
    /// Could not find the session identifier in the Universal Link URL.
    case invalidUniversalLinkURL

    /// Could not find the  session identifier in the QR code.
    case invalidQRCode

    /// Could not find the session identifier in the push notification payload.
    case invalidPushNotificationPayload

    /// The session identifier in the ``CrossDeviceSession`` is empty or blank.
    case invalidCrossDeviceSession

    /// Fetching the cross-device session failed.
    case getCrossDeviceSessionFail(Error?)

    /// Cross-device session abort failed.
    case abortCrossDeviceSessionFail(Error?)
}

extension CrossDeviceSessionError: Equatable {
    public static func == (
        lhs: CrossDeviceSessionError,
        rhs: CrossDeviceSessionError
    ) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension CrossDeviceSessionError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .invalidQRCode:
            return 1
        case .invalidUniversalLinkURL:
            return 2
        case .invalidPushNotificationPayload:
            return 3
        case .getCrossDeviceSessionFail:
            return 4
        case .invalidCrossDeviceSession:
            return 5
        case .abortCrossDeviceSessionFail:
            return 6
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .getCrossDeviceSessionFail(error), let .abortCrossDeviceSessionFail(error):
            if let error {
                return ["error": error]
            } else {
                return [String: Any]()
            }
        default:
            return [String: Any]()
        }
    }
}
