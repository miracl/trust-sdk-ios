/// Class used to log messages. It has a writer of messages.
/// - Tag: classes-MIRACLLogger
final class MIRACLLogger: Sendable {
    /// Writer used to write a message to the output. The default version uses `Unified System Logging` by Apple.
    let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    /// Sends messages with the `debug` level to the writer. Doesn't work on production builds.
    ///  - Parameters:
    ///  - message: message that needs to be logged.
    ///  - category: which category of the SDK is logged message.
    func debug(message: String, category: LogCategory) {
        #if DEBUG
            logger.debug(message: message, category: category)
        #endif
    }

    /// Sends messages with the `info` level to the writer. Doesn't work on production builds.
    /// - Parameters:
    ///  - message: message that needs to be logged.
    ///  - category: which category of the SDK is logged message.
    func info(message: String, category: LogCategory) {
        #if DEBUG
            logger.info(message: message, category: category)
        #endif
    }

    /// Sends messages with the `error` level to the writer. Doesn't work on production builds.
    /// - Parameters:
    ///  - message: message that needs to be logged.
    ///  - category: which category of the SDK is logged message.
    func error(message: String, category: LogCategory) {
        #if DEBUG
            logger.error(message: message, category: category)
        #endif
    }
}
