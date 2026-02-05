import Foundation

@objc public protocol SessionDetails: Sendable {
    /// User ID entered by the user when the session is started.
    var userId: String { get }

    /// Name of the project in the MIRACL Trust platform.
    var projectName: String { get }

    /// URL of the project logo.
    var projectLogoURL: String { get }

    /// Project ID setting for the application in the MIRACL Trust platform.
    var projectId: String { get }

    /// PIN length that the user must enter.
    var pinLength: Int { get }

    /// Indicates the method of user verification.
    var verificationMethod: VerificationMethod { get }

    /// URL for verification when custom user verification is used.
    var verificationURL: String { get }

    /// Custom text specified in the MIRACL Trust Portal for the custom user verification.
    var verificationCustomText: String { get }

    /// Label of the identity which will be used for user verification.
    var identityTypeLabel: String { get }

    /// Whether QuickCode is enabled for the project or not.
    var quickCodeEnabled: Bool { get }

    /// Identity type which will be used for user verification.
    var identityType: IdentityType { get }
}

/// Possible verification methods that can be used for user verification.
@objc public enum VerificationMethod: Int, Sendable {
    /// Custom user verification, done with a client implementation.
    case fullCustom

    /// User verification done by email.
    case standardEmail

    /// Gets the verification method based on the given string value. If no match is found, returns the `standardEmail` value.
    /// - Parameter string: value of the verification method.
    /// - Returns: value of the verification method.
    public static func verificationMethodFromString(
        _ string: String
    ) -> VerificationMethod {
        switch string {
        case "standardEmail":
            return .standardEmail
        case "fullCustom":
            return .fullCustom
        default:
            return .standardEmail
        }
    }
}

/// Possible identity types that can be used for user verification.
@objc public enum IdentityType: Int, Sendable {
    /// Identity is identified with an email address.
    case email

    /// Identity is identified with alphanumeric symbols.
    case alphanumeric

    public static func identityTypeFromString(
        _ string: String
    ) -> IdentityType {
        switch string {
        case "email":
            return .email
        case "alphanumeric":
            return .alphanumeric
        default:
            return .email
        }
    }
}
