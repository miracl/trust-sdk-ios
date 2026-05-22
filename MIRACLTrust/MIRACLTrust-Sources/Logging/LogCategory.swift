/// An enumeration of the categories for logging into the SDK.
@objc public enum LogCategory: Int {
    /// Logging into the `configuration` category.
    case configuration

    /// Logging into the `networking` category.
    case networking

    /// Logging into the `crypto` category.
    case crypto

    /// Logging into the `registration` category.
    case registration

    /// Logging into the `authentication` category.
    case authentication

    /// Logging into the `signing` category.
    case signing

    /// Logging into the `signing registration` category.
    case signingRegistration

    /// Logging into the `verification` category.
    case verification

    /// Logging into the `verification` category.
    case verificationConfirmation

    /// Logging into the `storage` category.
    case storage

    /// Logging into the `Session Management` category.
    case sessionManagement

    /// Logging into the `JWT Generation` category.
    case jwtGeneration

    /// Logging into the `QuickCode` category.
    case quickCode

    /// Logging into the `Device Tag` category.
    case deviceTag

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
        case .deviceTag:
            return "Device Tag"
        default:
            return ""
        }
    }
}
