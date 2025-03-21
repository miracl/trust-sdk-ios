import Foundation

/// An enumeration that describes signing issues.
public enum SigningError: Error {
    /// Empty message hash.
    case emptyMessageHash

    /// Public key of the signing identity is empty.
    case emptyPublicKey

    /// User object passed for signing is not valid.
    case invalidUserData

    /// Pin not entered.
    case pinCancelled

    /// Pin code includes invalid symbols or pin length does not match.
    case invalidPin

    /// Signing failed.
    case signingFail(Error?)

    /// The user is revoked because of too many unsuccessful authentication attempts or has not been used in a substantial amount of time. The device needs to be re-registered.
    case revoked

    /// The authentication was not successful.
    case unsuccessfulAuthentication

    /// Invalid or expired signing session.
    case invalidSigningSession

    /// The session identifier in SigningSessionDetails is empty or blank.
    case invalidSigningSessionDetails
}

extension SigningError: Equatable {
    public static func == (lhs: SigningError, rhs: SigningError) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension SigningError: LocalizedError {
    public var errorDescription: String? {
        var description = ""
        switch self {
        case .emptyMessageHash:
            description = NSLocalizedString("\(SigningError.emptyMessageHash)", comment: "")
        case .emptyPublicKey:
            description = NSLocalizedString("\(SigningError.emptyPublicKey)", comment: "")
        case .invalidUserData:
            description = NSLocalizedString("\(SigningError.invalidUserData)", comment: "")
        case .pinCancelled:
            description = NSLocalizedString("\(SigningError.pinCancelled)", comment: "")
        case .invalidPin:
            description = NSLocalizedString("\(SigningError.invalidPin)", comment: "")
        case .revoked:
            description = NSLocalizedString("\(SigningError.revoked)", comment: "")
        case let .signingFail(error):
            description = NSLocalizedString("\(SigningError.signingFail(error))", comment: "")
        case .unsuccessfulAuthentication:
            description = NSLocalizedString("\(SigningError.unsuccessfulAuthentication)", comment: "")
        case .invalidSigningSession:
            description = NSLocalizedString("\(SigningError.invalidSigningSession)", comment: "")
        case .invalidSigningSessionDetails:
            description = NSLocalizedString("\(SigningError.invalidSigningSessionDetails)", comment: "")
        }
        return description
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
