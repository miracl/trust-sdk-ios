/// Enums describing what are categories for logging into the SDK.
@objc public enum LogCategory: Int {
    /// Logging into `configuration` category.
    case configuration

    /// Logging into `networking` category.
    case networking

    /// Logging into `crypto` category.
    case crypto

    /// Logging into `registration` category.
    case registration

    /// Logging into `authentication` category.
    case authentication

    /// Logging into `signing` category.
    case signing

    /// Logging into `signing registration` category.
    case signingRegistration

    /// Logging into `verification` category.
    case verification

    /// Logging into `verification` category.
    case verificationConfirmation

    /// Logging into `storage` category.
    case storage

    /// Logging into `Session Management` category.
    case sessionManagement

    /// Logging into `JWT Generation` category.
    case jwtGeneration

    /// Logging into `QuickCode` category.
    case quickCode

    /// Describing category as string.
    var label: String {
        switch self {
        case .configuration:
            return "configuration"
        case .networking:
            return "networking"
        case .crypto:
            return "crypto"
        case .registration:
            return "registration"
        case .authentication:
            return "authentication"
        case .signing:
            return "signing"
        case .signingRegistration:
            return "signing registration"
        case .verification:
            return "verification"
        case .verificationConfirmation:
            return "verification confirmation"
        case .storage:
            return "storage"
        case .sessionManagement:
            return "Session Management"
        case .jwtGeneration:
            return "JWT Generation"
        case .quickCode:
            return "QuickCode"
        default:
            return ""
        }
    }
}
