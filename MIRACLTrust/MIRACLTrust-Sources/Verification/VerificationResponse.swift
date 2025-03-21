import Foundation

/// The response returned from [sendVerificationEmail](x-source-tag://miracltrust-_FUNC_sendverificationemailuseridauthenticationsessiondetailscompletionhandler).
@objcMembers
public final class VerificationResponse: NSObject, Sendable {
    /// Unix timestamp before a new verification email could be sent for the same user ID.
    public let backoff: Int64

    /// Indicates the method of the verification.
    public let method: EmailVerificationMethod

    init(backoff: Int64, method: EmailVerificationMethod) {
        self.backoff = backoff
        self.method = method
    }
}
