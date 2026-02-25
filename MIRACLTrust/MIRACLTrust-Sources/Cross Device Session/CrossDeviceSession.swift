import Foundation

/// An object representing details for an operation (authentication or signing)  started on another device.
@objcMembers
@objc public final class CrossDeviceSession: NSObject, Sendable {
    /// User ID entered by the user when session is started.
    public let userId: String

    /// Project ID setting for the application in MIRACL Trust platform.
    public let projectId: String

    /// Identifier of the session.
    public let sessionId: String

    /// Description of the operation that needs to be done.
    public let sessionDescription: String

    /// Hash of the transaction that needs to be signed if any.
    public let signingHash: String

    public init(
        userId: String,
        projectId: String,
        sessionId: String,
        sessionDescription: String,
        signingHash: String
    ) {
        self.userId = userId
        self.projectId = projectId
        self.sessionId = sessionId
        self.sessionDescription = sessionDescription
        self.signingHash = signingHash
    }

    override public var description: String {
        "CrossDeviceSession(userId: \(userId), projectId: \(projectId), sessionId: \(sessionId), sessionDescription: \(sessionDescription), signingHash: \(signingHash))"
    }
}
