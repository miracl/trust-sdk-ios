import Foundation

///  An enumeration that describes issues with the authentication session management.
public enum AuthenticationSessionError: Error {
    /// Could not find the session identifier in the Universal Link URL.
    case invalidUniversalLinkURL

    /// Could not find the session identifier in the QR code.
    case invalidQRCode

    /// Could not find the session identifier in the push notification payload.
    case invalidPushNotificationPayload

    /// The session identifier in SessionDetails is empty or blank.
    case invalidAuthenticationSessionDetails

    /// Fetching the authentication session details failed.
    case getAuthenticationSessionDetailsFail(Error?)

    /// Authentication session abort failed.
    case abortSessionFail(Error?)
}

extension AuthenticationSessionError: Equatable {
    public static func == (lhs: AuthenticationSessionError, rhs: AuthenticationSessionError) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension AuthenticationSessionError: LocalizedError {
    public var errorDescription: String? {
        var description = ""
        switch self {
        case .invalidQRCode:
            description = NSLocalizedString("\(AuthenticationSessionError.invalidQRCode)", comment: "")
        case .invalidUniversalLinkURL:
            description = NSLocalizedString("\(AuthenticationSessionError.invalidUniversalLinkURL)", comment: "")
        case .invalidPushNotificationPayload:
            description = NSLocalizedString("\(AuthenticationSessionError.invalidPushNotificationPayload)", comment: "")
        case .invalidAuthenticationSessionDetails:
            description = NSLocalizedString("\(AuthenticationSessionError.invalidAuthenticationSessionDetails)", comment: "")
        case let .getAuthenticationSessionDetailsFail(error):
            description = NSLocalizedString("\(AuthenticationSessionError.getAuthenticationSessionDetailsFail(error))", comment: "")
        case let .abortSessionFail(error):
            description = NSLocalizedString("\(AuthenticationSessionError.abortSessionFail(error))", comment: "")
        }
        return description
    }
}

extension AuthenticationSessionError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .invalidUniversalLinkURL:
            return 1
        case .invalidQRCode:
            return 2
        case .invalidPushNotificationPayload:
            return 3
        case .invalidAuthenticationSessionDetails:
            return 4
        case .getAuthenticationSessionDetailsFail:
            return 5
        case .abortSessionFail:
            return 6
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .abortSessionFail(error), let .getAuthenticationSessionDetailsFail(error):
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
