import Foundation

public enum SigningSessionError: Error {
    /// Could not find the signing session identifier in the Universal Link URL.
    case invalidUniversalLinkURL

    /// Could not find the signing session identifier in the QR code.
    case invalidQRCode

    /// The session identifier in SigningSessionDetails is empty or blank.
    case invalidSigningSessionDetails

    /// Fetching the signing session details failed.
    case getSigningSessionDetailsFail(Error?)

    /// Invalid or expired signing session.
    case invalidSigningSession

    /// Abort of the signing session has failed.
    case abortSigningSessionFail(Error?)
}

extension SigningSessionError: Equatable {
    public static func == (lhs: SigningSessionError, rhs: SigningSessionError) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension SigningSessionError: LocalizedError {
    public var errorDescription: String? {
        var description = ""
        switch self {
        case .invalidQRCode:
            description = NSLocalizedString("\(SigningSessionError.invalidQRCode)", comment: "")
        case .invalidUniversalLinkURL:
            description = NSLocalizedString("\(SigningSessionError.invalidUniversalLinkURL)", comment: "")
        case let .getSigningSessionDetailsFail(error):
            description = NSLocalizedString("\(SigningSessionError.getSigningSessionDetailsFail(error))", comment: "")
        case .invalidSigningSessionDetails:
            description = NSLocalizedString("\(SigningSessionError.invalidSigningSessionDetails)", comment: "")
        case .invalidSigningSession:
            description = NSLocalizedString("\(SigningSessionError.invalidSigningSession)", comment: "")
        case let .abortSigningSessionFail(error):
            description = NSLocalizedString("\(SigningSessionError.abortSigningSessionFail(error))", comment: "")
        }
        return description
    }
}

extension SigningSessionError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .invalidUniversalLinkURL:
            return 1
        case .invalidQRCode:
            return 2
        case .invalidSigningSessionDetails:
            return 3
        case .getSigningSessionDetailsFail:
            return 4
        case .invalidSigningSession:
            return 5
        case .abortSigningSessionFail:
            return 6
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .getSigningSessionDetailsFail(error), let .abortSigningSessionFail(error):
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
