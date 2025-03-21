import Foundation

/// An enumeration that describes registration issues.
public enum RegistrationError: Error {
    /// Empty user ID.
    case emptyUserId

    // Empty activation token.
    case emptyActivationToken

    /// Invalid activation token.
    case invalidActivationToken

    /// Registration failed.
    case registrationFail(Error?)

    /// Curve returned by the platform is unsupported by this version of the SDK.
    case unsupportedEllipticCurve

    /// Pin not entered.
    case pinCancelled

    /// Pin code includes invalid symbols or pin length does not match.
    case invalidPin

    /// The registration was started for a different project.
    case projectMismatch
}

extension RegistrationError: LocalizedError {
    public var errorDescription: String? {
        var description = ""
        switch self {
        case .emptyUserId:
            description = NSLocalizedString("\(RegistrationError.emptyUserId)", comment: "")
        case .invalidActivationToken:
            description = NSLocalizedString("\(RegistrationError.invalidActivationToken)", comment: "")
        case let .registrationFail(error):
            description = NSLocalizedString("\(RegistrationError.registrationFail(error))", comment: "")
        case .unsupportedEllipticCurve:
            description = NSLocalizedString("\(RegistrationError.unsupportedEllipticCurve)", comment: "")
        case .pinCancelled:
            description = NSLocalizedString("\(RegistrationError.pinCancelled)", comment: "")
        case .invalidPin:
            description = NSLocalizedString("\(RegistrationError.invalidPin)", comment: "")
        case .emptyActivationToken:
            description = NSLocalizedString("\(RegistrationError.emptyActivationToken)", comment: "")
        case .projectMismatch:
            description = NSLocalizedString("\(RegistrationError.projectMismatch)", comment: "")
        }
        return description
    }
}

extension RegistrationError: Equatable {
    public static func == (
        lhs: RegistrationError,
        rhs: RegistrationError
    ) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension RegistrationError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .emptyUserId:
            return 1
        case .emptyActivationToken:
            return 2
        case .invalidActivationToken:
            return 3
        case .registrationFail:
            return 4
        case .unsupportedEllipticCurve:
            return 5
        case .pinCancelled:
            return 6
        case .invalidPin:
            return 7
        case .projectMismatch:
            return 8
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .registrationFail(error):
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
