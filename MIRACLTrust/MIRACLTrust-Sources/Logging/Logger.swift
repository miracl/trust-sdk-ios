import Foundation

/// Protocol describing possible outputs for logging messages.
/// - Tag: protocols-Logger
@objc public protocol Logger: Sendable {
    /// Outputs message with `debug` level.
    /// - Parameters:
    ///   - message: message that needs to be logged.
    ///   - category: which category of the SDK is the  logged message.
    func debug(message: String, category: LogCategory)

    /// Outputs message with `info` level.
    /// - Parameters:
    ///   - message: message that needs to be logged.
    ///   - category: which category of the SDK is the logged message.
    func info(message: String, category: LogCategory)

    /// Outputs message with `warning` level.
    /// - Parameters:
    ///   - message: message that needs to be logged.
    ///   - category: which category of the SDK is the logged message.
    func warning(message: String, category: LogCategory)

    /// Outputs message with `error` level.
    /// - Parameters:
    ///   - message: message that needs to be logged.
    ///   - category: which category of the SDK is the logged message.
    func error(message: String, category: LogCategory)
}
