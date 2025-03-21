import os.log

private let subsystem = "com.miracl.trust.sdk-iOS"

extension OSLog {
    static let configuration = OSLog(
        subsystem: subsystem,
        category: LogCategory.configuration.label
    )

    static let networking = OSLog(
        subsystem: subsystem,
        category: LogCategory.networking.label
    )

    static let crypto = OSLog(
        subsystem: subsystem,
        category: LogCategory.crypto.label
    )

    static let registration = OSLog(
        subsystem: subsystem,
        category: LogCategory.registration.label
    )

    static let authentication = OSLog(
        subsystem: subsystem,
        category: LogCategory.authentication.label
    )

    static let signing = OSLog(
        subsystem: subsystem,
        category: LogCategory.signing.label
    )

    static let signingRegistration = OSLog(
        subsystem: subsystem,
        category: LogCategory.signingRegistration.label
    )

    static let verification = OSLog(
        subsystem: subsystem,
        category: LogCategory.verification.label
    )

    static let verificationConfirmation = OSLog(
        subsystem: subsystem,
        category: LogCategory.verificationConfirmation.label
    )

    static let storage = OSLog(
        subsystem: subsystem,
        category: LogCategory.storage.label
    )

    static let sessionManagement = OSLog(
        subsystem: subsystem,
        category: LogCategory.sessionManagement.label
    )

    static let jwtGeneration = OSLog(
        subsystem: subsystem,
        category: LogCategory.jwtGeneration.label
    )

    static let quickCode = OSLog(
        subsystem: subsystem,
        category: LogCategory.quickCode.label
    )
}
