import Foundation

/// The response returned from [getActivationToken](x-source-tag://miracltrust-_FUNC_getactivationtokenverificationurlcompletionhandler).
@objcMembers
@objc public final class ActivationTokenResponse: NSObject, Sendable {
    /// The activation token returned after successful user verification.
    public let activationToken: String

    // Identifier of the project against which the verification is performed.
    public let projectId: String

    // Identifier of the user that is currently verified.
    public let userId: String

    // Identifier of the session from which the verification started.
    public let accessId: String?

    init(
        activationToken: String,
        projectId: String,
        userId: String,
        accessId: String?
    ) {
        self.activationToken = activationToken
        self.projectId = projectId
        self.userId = userId
        self.accessId = accessId
    }
}
