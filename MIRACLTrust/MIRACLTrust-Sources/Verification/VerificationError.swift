import Foundation

/// An enumeration that describes verification issues.
public enum VerificationError: Error {
    /// Empty user ID.
    case emptyUserId

    /// The session identifier in SessionDetails is empty or blank.
    case invalidSessionDetails

    /// Verification failed.
    case verificaitonFail(Error?)

    /// Too many verification requests. Wait for the `backoff` period.
    /// - Parameters:
    ///     - backoff: Unix timestamp before a new verification email could be sent for the same user ID.
    case requestBackoff(backoff: Int64)
}

extension VerificationError: Equatable {
    public static func == (lhs: VerificationError, rhs: VerificationError) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension VerificationError: LocalizedError {
    public var errorDescription: String? {
        var description = ""
        switch self {
        case .emptyUserId:
            description = NSLocalizedString("\(VerificationError.emptyUserId)", comment: "")
        case .invalidSessionDetails:
            description = NSLocalizedString("\(VerificationError.invalidSessionDetails)", comment: "")
        case let .verificaitonFail(error):
            description = NSLocalizedString("\(VerificationError.verificaitonFail(error))", comment: "")
        case let .requestBackoff(backoff):
            description = NSLocalizedString("\(VerificationError.requestBackoff(backoff: backoff))", comment: "")
        }
        return description
    }
}

extension VerificationError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .emptyUserId:
            return 1
        case .invalidSessionDetails:
            return 2
        case .verificaitonFail:
            return 3
        case .requestBackoff:
            return 4
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .verificaitonFail(error):
            if let error {
                return ["error": error]
            } else {
                return [String: Any]()
            }
        case let .requestBackoff(backoff: backoff):
            return ["backoff": backoff]
        default:
            return [String: Any]()
        }
    }
}
