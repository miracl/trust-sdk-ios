import Foundation

/// The response returned by ``MIRACLTrust/MIRACLTrust/sendVerificationEmail(userId:authenticationSessionDetails:completionHandler:)``.
@objcMembers
public final class VerificationResponse: NSObject, Sendable {
    /// Unix timestamp before a new verification email could be sent for the same User ID.
    public let backoff: Int64

    /// Indicates the method of verification.
    public let method: EmailVerificationMethod

    init(backoff: Int64, method: EmailVerificationMethod) {
        self.backoff = backoff
        self.method = method
    }

    override public var description: String {
        "VerificationResponse(backoff: \(backoff), method: \(method))"
    }
}
