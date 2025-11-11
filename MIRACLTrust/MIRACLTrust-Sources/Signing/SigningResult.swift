import Foundation

/// Result returned by ``MIRACLTrust/MIRACLTrust/sign(message:user:didRequestSigningPinHandler:completionHandler:)`` method.
@objcMembers
public final class SigningResult: NSObject, Sendable {
    /// Cryptographic representation of the signature
    public let signature: Signature

    /// When the document has been signed.
    public let timestamp: Date

    override public var description: String {
        "SigningResult(signature: \(signature), timestamp: \(timestamp))"
    }

    init(
        signature: Signature,
        timestamp: Date
    ) {
        self.signature = signature
        self.timestamp = timestamp
    }
}
