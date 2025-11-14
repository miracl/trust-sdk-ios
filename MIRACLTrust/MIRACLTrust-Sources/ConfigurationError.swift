import Foundation

/// An enumeration that describes issues with the SDK configuration.
public enum ConfigurationError: Error, Equatable, DefaultLocalizedError {
    // Empty Proejct ID.
    case emptyProjectId

    // Invalid project URL.
    case invalidProjectURL
}
