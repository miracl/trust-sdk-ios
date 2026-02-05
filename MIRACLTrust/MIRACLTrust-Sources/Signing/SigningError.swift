import Foundation

/// An enumeration describing signing issues.
public enum SigningError: Error, DefaultLocalizedError {
    /// Empty message hash.
    case emptyMessageHash

    /// Public key of the signing identity is empty.
    case emptyPublicKey

    /// User object passed for signing is not valid.
    case invalidUserData

    /// PIN code was not entered.
    case pinCancelled

    /// PIN code contains invalid symbols or PIN length does not match.
    case invalidPin

    /// Signing failed.
    case signingFail(Error?)

    /// The user was revoked due to too many failed authentication attempts or prolonged inactivity. The device must be re-registered.
    case revoked

    /// The authentication was not successful.
    case unsuccessfulAuthentication

    /// Invalid or expired signing session.
    case invalidSigningSession

    /// The session identifier in `SigningSessionDetails` is empty or blank.
    case invalidSigningSessionDetails
}

extension SigningError: Equatable {
    public static func == (lhs: SigningError, rhs: SigningError) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension SigningError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .emptyMessageHash:
            return 1
        case .emptyPublicKey:
            return 2
        case .invalidUserData:
            return 3
        case .pinCancelled:
            return 4
        case .invalidPin:
            return 5
        case .signingFail:
            return 6
        case .revoked:
            return 7
        case .unsuccessfulAuthentication:
            return 8
        case .invalidSigningSession:
            return 9
        case .invalidSigningSessionDetails:
            return 10
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .signingFail(error):
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
