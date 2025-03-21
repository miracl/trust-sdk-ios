import Foundation

/// An enumeration that describes issues with the SDK configuration.
/// - Tag: enums-ConfigurationError
public enum ConfigurationError: Error, Equatable {
    // Empty Proejct ID.
    case configurationEmptyProjectId
}

extension ConfigurationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .configurationEmptyProjectId:
            return NSLocalizedString("\(ConfigurationError.configurationEmptyProjectId)", comment: "")
        }
    }
}
