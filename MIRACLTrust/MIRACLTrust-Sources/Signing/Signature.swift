import Foundation

@objcMembers
@objc public final class Signature: NSObject, Codable, Sendable {
    public let mpinId: String
    public let U: String
    public let V: String
    public let publicKey: String
    public let dtas: String
    public let signatureHash: String
    public let timestamp: Int64

    enum CodingKeys: String, CodingKey {
        case mpinId
        case U = "u"
        case V = "v"
        case publicKey
        case dtas
        case signatureHash = "hash"
        case timestamp
    }

    init(
        mpinId: String,
        U: String,
        V: String,
        publicKey: String,
        dtas: String,
        signatureHash: String,
        timestamp: Date
    ) {
        self.mpinId = mpinId
        self.U = U
        self.V = V
        self.publicKey = publicKey
        self.dtas = dtas
        self.signatureHash = signatureHash
        self.timestamp = Int64(timestamp.timeIntervalSince1970)
    }

    @available(swift, obsoleted: 1.0)
    public func dictionary() -> [String: Any] {
        [
            "mpinId": mpinId,
            "u": U,
            "v": V,
            "publicKey": publicKey,
            "dtas": dtas,
            "hash": signatureHash,
            "timestamp": timestamp
        ]
    }
}
