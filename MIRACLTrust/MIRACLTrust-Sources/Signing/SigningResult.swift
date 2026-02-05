import Foundation

/// Result returned by the ``MIRACLTrust/MIRACLTrust/sign(message:user:didRequestSigningPinHandler:completionHandler:)`` method.
@objcMembers
public final class SigningResult: NSObject, Sendable {
    /// Cryptographic representation of the signature.
    public let signature: Signature

    /// Shows when the document was signed.
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
