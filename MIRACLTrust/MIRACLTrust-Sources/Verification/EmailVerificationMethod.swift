import Foundation

/// Possible email verification methods.
@objc public enum EmailVerificationMethod: Int, Sendable {
    /// Verification link is sent to the user's email.
    case link

    /// Verification code is sent to the user's email.
    case code

    /// Gets the email verification method based on the given string value. If the method is not matched, it returns the `link` value.
    /// - Parameter string: value of the email verification method
    /// - Returns: Value of the email verification method.
    public static func emailVerificationMethodFromString(
        _ string: String
    ) -> EmailVerificationMethod {
        switch string {
        case "link":
            return .link
        case "code":
            return .code
        default:
            return .link
        }
    }
}
