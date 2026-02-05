import CommonCrypto
import Foundation

/// Representing a user in the MIRACL Trust platform.
/// This user has authentication and signing identities.
@objcMembers
@objc public final class User: NSObject, Sendable {
    /// Identifier of the user (e.g email address).
    public let userId: String

    /// Identifier of the project in the MIRACL Trust platform.
    public let projectId: String

    /// Provides information on whether the user has been revoked or not.
    public let revoked: Bool

    /// The PIN's number of digits.
    public let pinLength: Int

    /// Actual representation of the identity.
    let mpinId: Data

    /// The second factor of the authentication.
    let token: Data

    /// Base64-encoded URLs of the DTAs.
    let dtas: String

    /// The public part of the signing key.
    let publicKey: Data?

    init(
        userId: String,
        projectId: String,
        revoked: Bool,
        pinLength: Int,
        mpinId: Data,
        token: Data,
        dtas: String,
        publicKey: Data?
    ) {
        self.userId = userId
        self.projectId = projectId
        self.revoked = revoked
        self.pinLength = pinLength
        self.mpinId = mpinId
        self.token = token
        self.dtas = dtas
        self.publicKey = publicKey
    }

    /// Hex-encoded SHA256 representation of the `mpinId` property.
    public var hashedMpinId: String {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        mpinId.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(mpinId.count), &hash)
        }

        return Data(hash).hex
    }

    /// Check whether any of the `dtas`, `mpinId` or `token` properties has a value.
    /// - Returns: whether any of the `dtas`, `mpinId` or `token` properties has a value.
    func emptyUser() -> Bool {
        dtas.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            mpinId.isEmpty ||
            token.isEmpty
    }

    func revoke() -> User {
        User(
            userId: userId,
            projectId: projectId,
            revoked: true,
            pinLength: pinLength,
            mpinId: mpinId,
            token: token,
            dtas: dtas,
            publicKey: publicKey
        )
    }

    override public var description: String {
        "User(userId: \(userId), projectId: \(projectId), revoked: \(revoked), pinLength: \(pinLength), hashedMpinId: \(hashedMpinId), token: \(REDACTED_STRING), dtas: \(dtas), publicKey: \(String(describing: publicKey)))"
    }
}

extension User {
    func toUserDTO() -> UserDTO {
        UserDTO(
            userId: userId,
            projectId: projectId,
            revoked: revoked,
            pinLength: pinLength,
            mpinId: mpinId,
            token: token,
            dtas: dtas,
            publicKey: publicKey
        )
    }
}
