import Foundation

/// The response returned from [getActivationToken](x-source-tag://miracltrust-_FUNC_getactivationtokenverificationurlcompletionhandler).
/// when there is an error in the request.
/// - Tag: classes-ActivationTokenErrorResponse
@objcMembers
@objc public final class ActivationTokenErrorResponse: NSObject, Sendable {
    // Identifier of the project against which the verification is performed.
    public let projectId: String

    // Identifier of the user for which the verification is performed.
    public let userId: String

    // Identifier of the session from which the verification started.
    public let accessId: String?

    init(projectId: String, userId: String, accessId: String?) {
        self.projectId = projectId
        self.userId = userId
        self.accessId = accessId
    }
}
