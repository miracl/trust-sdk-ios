/// Enum describing on what level messages will be logged or logging will be turned off.
/// - Tag: enums-LoggingLevel
@objc public enum LoggingLevel: Int, Comparable, Sendable {
    /// Logging is not allowed.
    case none = 0

    /// Messages will be logged until the `debug` level.
    case debug = 1

    /// Messages will be logged until the `info` level.
    case info = 2

    /// Messages will be logged until the `warning` level.
    case warning = 3

    /// Messages will be logged until the `error` level.
    case error = 4

    /// Returns a Boolean value indicating whether the value of the first
    /// argument is less than that of the second argument.
    ///
    /// - Parameters:
    ///  - lhs: A value to compare.
    ///  - rhs: Another value to compare.
    public static func < (lhs: LoggingLevel, rhs: LoggingLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
