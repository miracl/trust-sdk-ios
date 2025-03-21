import os.log

/// Default implementation of [LoggingMessageWriter](x-source-tag://protocols-LoggingMessageWriter) , that uses `os_log`.
final class DefaultLogger: Logger {
    let level: LoggingLevel

    init(level: LoggingLevel) {
        self.level = level
    }

    /// Logs message with `debug` level.
    /// - Parameters:
    ///   - message: message that needs to be logged.
    ///   - category: which category of the SDK is logged message.
    func debug(message: String, category: LogCategory) {
        if level > .debug || level == .none { return }

        log(message: message, category: category, type: .debug)
    }

    /// Logs message with `info` level.
    /// - Parameters:
    ///   - message: message that needs to be logged.
    ///   - category: which category of the SDK is logged message.
    func info(message: String, category: LogCategory) {
        if level > .info || level == .none { return }

        log(message: message, category: category, type: .info)
    }

    /// Logs message with `warning` level.
    /// - Parameters:
    ///   - message: message that needs to be logged.
    ///   - category: which category of the SDK is logged message.
    func warning(message: String, category: LogCategory) {
        if level > .warning || level == .none { return }

        log(message: message, category: category, type: .fault)
    }

    /// Logs message with `error` level.
    /// - Parameters:
    ///   - message: message that needs to be logged.
    ///   - category: which category of the SDK is logged message.
    func error(message: String, category: LogCategory) {
        if level > .error || level == .none { return }

        log(message: message, category: category, type: .error)
    }

    // MARK: Private

    private func log(message: String, category: LogCategory, type: OSLogType) {
        os_log(
            "%@",
            log: getOSLogByCategory(category: category),
            type: type,
            message
        )
    }

    private func getOSLogByCategory(category: LogCategory) -> OSLog {
        switch category {
        case .configuration:
            return OSLog.configuration
        case .networking:
            return OSLog.networking
        case .crypto:
            return OSLog.crypto
        case .authentication:
            return OSLog.authentication
        case .registration:
            return OSLog.registration
        case .signing:
            return OSLog.signing
        case .signingRegistration:
            return OSLog.signingRegistration
        case .verification:
            return OSLog.verification
        case .verificationConfirmation:
            return OSLog.verificationConfirmation
        case .storage:
            return OSLog.storage
        case .sessionManagement:
            return OSLog.sessionManagement
        case .jwtGeneration:
            return OSLog.jwtGeneration
        case .quickCode:
            return OSLog.quickCode
        }
    }
}
