import Foundation

/// An enumeration describing QuickCode issues.
public enum QuickCodeError: Error, DefaultLocalizedError {
    /// The user was revoked due to too many failed authentication attempts or prolonged inactivity. The device must be re-registered.
    case revoked

    /// The authentication was not successful.
    case unsuccessfulAuthentication

    /// PIN code was not entered.
    case pinCancelled

    /// PIN code contains invalid symbols or PIN length does not match.
    case invalidPin

    /// QuickCode generation failed.
    case generationFail(Error?)
}

extension QuickCodeError: Equatable {
    public static func == (lhs: QuickCodeError, rhs: QuickCodeError) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension QuickCodeError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .revoked:
            1
        case .unsuccessfulAuthentication:
            2
        case .pinCancelled:
            3
        case .invalidPin:
            4
        case .generationFail:
            5
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .generationFail(error):
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
