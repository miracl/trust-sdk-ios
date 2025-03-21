import Foundation

/// An enumeration that describes QuickCode issues.
public enum QuickCodeError: Error {
    /// The user is revoked because of too many unsuccessful authentication attempts or has not been used in a substantial amount of time. The device needs to be re-registered.
    case revoked

    /// The authentication was not successful.
    case unsuccessfulAuthentication

    /// Pin not entered.
    case pinCancelled

    /// Pin code includes invalid symbols or pin length does not match.
    case invalidPin

    /// Generating QuickCode from this registration is not allowed.
    case limitedQuickCodeGeneration

    /// QuickCode generation failed.
    case generationFail(Error?)
}

extension QuickCodeError: Equatable {
    public static func == (lhs: QuickCodeError, rhs: QuickCodeError) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension QuickCodeError: LocalizedError {
    public var errorDescription: String? {
        var description = ""
        switch self {
        case .revoked:
            description = NSLocalizedString("\(QuickCodeError.revoked)", comment: "")
        case .unsuccessfulAuthentication:
            description = NSLocalizedString("\(QuickCodeError.unsuccessfulAuthentication)", comment: "")
        case .pinCancelled:
            description = NSLocalizedString("\(QuickCodeError.pinCancelled)", comment: "")
        case .invalidPin:
            description = NSLocalizedString("\(QuickCodeError.invalidPin)", comment: "")
        case .limitedQuickCodeGeneration:
            description = NSLocalizedString("\(QuickCodeError.limitedQuickCodeGeneration)", comment: "")
        case let .generationFail(error):
            description = NSLocalizedString("\(QuickCodeError.generationFail(error))", comment: "")
        }
        return description
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
        case .limitedQuickCodeGeneration:
            5
        case .generationFail:
            6
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
