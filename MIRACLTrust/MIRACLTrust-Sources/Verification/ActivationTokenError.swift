import Foundation

/// An enumeration that describes issues with verification confirmation.
public enum ActivationTokenError: Error {
    /// Empty user ID in the universal link.
    case emptyUserId

    /// Empty verification code in the universal link.
    case emptyVerificationCode

    /// Invalid or expired activation code. There may be [ActivationTokenErrorResponse](x-source-tag://classes-ActivationTokenErrorResponse) in the error.
    case unsuccessfulVerification(activationTokenErrorResponse: ActivationTokenErrorResponse?)

    /// The request for fetching the activation token failed.
    case getActivationTokenFail(Error?)
}

extension ActivationTokenError: Equatable {
    public static func == (lhs: ActivationTokenError, rhs: ActivationTokenError) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension ActivationTokenError: LocalizedError {
    public var errorDescription: String? {
        var description = ""
        switch self {
        case .emptyVerificationCode:
            description = NSLocalizedString("\(ActivationTokenError.emptyVerificationCode)", comment: "")
        case .emptyUserId:
            description = NSLocalizedString("\(ActivationTokenError.emptyUserId)", comment: "")
        case let .getActivationTokenFail(cause):
            description = NSLocalizedString("\(ActivationTokenError.getActivationTokenFail(cause))", comment: "")
        case .unsuccessfulVerification:
            description = NSLocalizedString("\(String(describing: ActivationTokenError.unsuccessfulVerification))", comment: "")
        }
        return description
    }
}

extension ActivationTokenError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .emptyUserId:
            return 1
        case .emptyVerificationCode:
            return 2
        case .unsuccessfulVerification:
            return 3
        case .getActivationTokenFail:
            return 4
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .unsuccessfulVerification(activationTokenErrorResponse):
            if let activationTokenErrorResponse = activationTokenErrorResponse {
                var activationTokenErrorResponseUserInfo = [String: Any]()
                activationTokenErrorResponseUserInfo["activationTokenErrorResponse"] = activationTokenErrorResponse

                return activationTokenErrorResponseUserInfo
            } else {
                return [String: Any]()
            }
        case let .getActivationTokenFail(error):
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
