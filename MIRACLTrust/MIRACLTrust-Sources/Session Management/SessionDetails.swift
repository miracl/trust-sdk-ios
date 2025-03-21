import Foundation

@objc public protocol SessionDetails: Sendable {
    /// User id entered by the user when session is started.
    var userId: String { get }

    /// Name of the project in MIRACL platform.
    var projectName: String { get }

    /// URL of the project logo.
    var projectLogoURL: String { get }

    /// Project id setting for the application in MIRACL platform.
    var projectId: String { get }

    /// Pin Length that needs to be entered from user.
    var pinLength: Int { get }

    /// Indicates the method of user verification.
    var verificationMethod: VerificationMethod { get }

    /// URL for verification in case of custom verification method
    var verificationURL: String { get }

    /// Custom text specified in the MIRACL Trust portal for the custom verification.
    var verificationCustomText: String { get }

    /// Label of the identity which will be used for identity verification.
    var identityTypeLabel: String { get }

    /// Whether the QuickCode is enabled for the project or not.
    var quickCodeEnabled: Bool { get }

    /// Flag indicating whether registration with QuickCode is allowed for identities registered also with QuickCode.
    var limitQuickCodeRegistration: Bool { get }

    /// Identity type which will be used for identity verification.
    var identityType: IdentityType { get }
}

/// Possible verification methods that can be used for identity verification.
@objc public enum VerificationMethod: Int, Sendable {
    /// Custom identity verification, done with a client implementation.
    case fullCustom

    /// Identity verification done by email.
    case standardEmail

    /// Getting the verification method based on the given string value. If the method is not matched returns the `standardEmail` value.
    /// - Parameter string: value of the verification method
    /// - Returns: Value of the verification method.
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

/// Possible identity types that can be used for identity verification.
@objc public enum IdentityType: Int, Sendable {
    // Identity is identified with email.
    case email

    // Identity is identified with alphanumeric symbols.
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
