import Foundation

/// An enumeration that describes QuickCode issues.
public enum QuickCodeError: Error, DefaultLocalizedError {
    /// The user is revoked because of too many unsuccessful authentication attempts or has not been used in a substantial amount of time. The device needs to be re-registered.
    case revoked

    /// The authentication was not successful.
    case unsuccessfulAuthentication

    /// Pin not entered.
    case pinCancelled

    /// Pin code includes invalid symbols or pin length does not match.
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
