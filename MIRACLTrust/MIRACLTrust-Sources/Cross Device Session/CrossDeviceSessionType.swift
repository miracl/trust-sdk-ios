import Foundation

/// Represents the type of ``CrossDeviceSession``
///
/// Use this enum to determine the appropriate flow when handling the session.
@objc public enum CrossDeviceSessionType: Int, Sendable {
    /// Indicates an authentication session.
    case authentication

    /// Indicates a signing session.
    case signing
}
