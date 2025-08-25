import Foundation

/// An enumeration that describes issues with the SDK configuration.
public enum ConfigurationError: Error, Equatable {
    // Empty Proejct ID.
    case emptyProjectId

    // Invalid project URL.
    case invalidProjectURL
}

extension ConfigurationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyProjectId:
            return NSLocalizedString("\(ConfigurationError.emptyProjectId)", comment: "")
        case .invalidProjectURL:
            return NSLocalizedString("\(ConfigurationError.invalidProjectURL)", comment: "")
        }
    }
}
