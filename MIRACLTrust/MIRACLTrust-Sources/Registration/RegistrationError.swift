import Foundation

/// An enumeration describing registration issues.
public enum RegistrationError: Error, DefaultLocalizedError {
    /// Empty User ID.
    case emptyUserId

    /// Empty activation token.
    case emptyActivationToken

    /// Invalid activation token.
    case invalidActivationToken

    /// Registration failed.
    case registrationFail(Error?)

    /// Curve returned by the platform is unsupported by this version of the SDK.
    @available(*, deprecated, message: "This error is no longer returned and will be removed in a future release.")
    case unsupportedEllipticCurve

    /// PIN code was not entered.
    case pinCancelled

    /// PIN code contains invalid symbols or PIN length does not match.
    case invalidPin

    /// The registration was started for a different project.
    case projectMismatch
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
