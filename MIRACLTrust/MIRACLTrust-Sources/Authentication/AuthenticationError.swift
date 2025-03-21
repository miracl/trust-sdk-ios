import Foundation

/// An enumeration that describes authentication issues.
public enum AuthenticationError: Error {
    /// User object passed for authentication is not valid.
    case invalidUserData

    /// Could not find the session identifier in the QR code.
    case invalidQRCode

    /// Could not find a valid projectID, qrURL, or userID in the push notification payload.
    case invalidPushNotificationPayload

    /// There isn't a registered user for the provided user ID and project in the push notification payload.
    case userNotFound

    /// Could not find the session identifier in the Universal Link.
    case invalidUniversalLink

    // Authentication failed.
    case authenticationFail(Error?)

    /// The user is revoked because of too many unsuccessful authentication attempts or has not been used in a substantial amount of time. The device needs to be re-registered.
    case revoked

    /// Invalid or expired authentication session.
    case invalidAuthenticationSession

    /// The authentication was not successful.
    case unsuccessfulAuthentication

    /// Pin not entered.
    case pinCancelled

    /// Pin code includes invalid symbols or pin length does not match.
    case invalidPin
}

extension AuthenticationError: Equatable {
    public static func == (lhs: AuthenticationError, rhs: AuthenticationError) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension AuthenticationError: LocalizedError {
    public var errorDescription: String? {
        var description = ""
        switch self {
        case .invalidUserData:
            description = NSLocalizedString("\(AuthenticationError.invalidUserData)", comment: "")
        case .invalidQRCode:
            description = NSLocalizedString("\(AuthenticationError.invalidQRCode)", comment: "")
        case .invalidPushNotificationPayload:
            description = NSLocalizedString("\(AuthenticationError.invalidPushNotificationPayload)", comment: "")
        case .userNotFound:
            description = NSLocalizedString("\(AuthenticationError.userNotFound)", comment: "")
        case .invalidUniversalLink:
            description = NSLocalizedString("\(AuthenticationError.invalidUniversalLink)", comment: "")
        case .pinCancelled:
            description = NSLocalizedString("\(AuthenticationError.pinCancelled)", comment: "")
        case .invalidPin:
            description = NSLocalizedString("\(AuthenticationError.invalidPin)", comment: "")
        case .revoked:
            description = NSLocalizedString("\(AuthenticationError.revoked)", comment: "")
        case .invalidAuthenticationSession:
            description = NSLocalizedString("\(AuthenticationError.invalidAuthenticationSession)", comment: "")
        case .unsuccessfulAuthentication:
            description = NSLocalizedString("\(AuthenticationError.unsuccessfulAuthentication)", comment: "")
        case let .authenticationFail(error):
            description = NSLocalizedString("\(AuthenticationError.authenticationFail(error))", comment: "")
        }
        return description
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
