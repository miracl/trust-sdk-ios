import Foundation

/// The response returned from ``MIRACLTrust/MIRACLTrust/getActivationToken(verificationURL:completionHandler:)``
/// and ``MIRACLTrust/MIRACLTrust/getActivationToken(userId:code:completionHandler:)``
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
