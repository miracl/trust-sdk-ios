import Foundation

/// An enumeration describing authentication issues.
public enum AuthenticationError: Error, DefaultLocalizedError {
    /// User object passed for authentication is not valid.
    case invalidUserData

    /// Could not find the session identifier in the QR code.
    case invalidQRCode

    /// Could not find a valid projectID, qrURL, or userID in the push notification payload.
    case invalidPushNotificationPayload

    /// There is no registered user for the provided User ID and project in the push notification payload.
    case userNotFound

    /// Could not find the session identifier in the Universal Link.
    case invalidUniversalLink

    /// Authentication failed.
    case authenticationFail(Error?)

    /// The user was revoked due to too many failed authentication attempts or prolonged inactivity. The device must be re-registered.
    case revoked

    /// Invalid or expired authentication session.
    case invalidAuthenticationSession

    /// The authentication was not successful.
    case unsuccessfulAuthentication

    /// PIN code was not entered.
    case pinCancelled

    /// PIN code contains invalid symbols or PIN length does not match.
    case invalidPin

    /// Invalid or expired cross-device session.
    case invalidCrossDeviceSession
}

extension AuthenticationError: Equatable {
    public static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension AuthenticationError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .invalidUserData:
            return 1
        case .invalidQRCode:
            return 2
        case .invalidPushNotificationPayload:
            return 3
        case .userNotFound:
            return 4
        case .invalidUniversalLink:
            return 5
        case .authenticationFail:
            return 6
        case .revoked:
            return 7
        case .invalidAuthenticationSession:
            return 8
        case .unsuccessfulAuthentication:
            return 9
        case .pinCancelled:
            return 10
        case .invalidPin:
            return 11
        case .invalidCrossDeviceSession:
            return 12
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .authenticationFail(error):
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
