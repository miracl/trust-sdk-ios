import Foundation

/// An enumeration describing issues with the SDK configuration.
public enum ConfigurationError: Error, Equatable, DefaultLocalizedError {
    /// Empty Project ID.
    case emptyProjectId

    /// Invalid project URL.
    case invalidProjectURL
}
