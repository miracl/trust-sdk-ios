import Foundation

/// Defines the persistent data representation of a user.
///
/// A user is uniquely identified by the composite key of (`userId`, `projectId`).
///
/// - warning: This object contains sensitive data.
/// Implementers must ensure secure storage (e.g., encryption at rest).
public final class UserDTO: NSObject, Sendable {
    /// The identifier of the user, which is unique within the scope of a project (e.g., email, username, etc.).
    public let userId: String

    /// The identifier of the project to which the user belongs.
    public let projectId: String

    /// The revocation status of the user.
    public let revoked: Bool

    /// The number of digits of the user's PIN.
    public let pinLength: Int

    /// The identifier of this user registration in the MIRACL Trust platform.
    public let mpinId: Data

    /// A secure user token.
    ///
    /// - warning:
    ///  This field contain sensitive data. The storage implementation
    /// is responsible for its secure handling, including encryption at rest.
    public let token: Data

    /// Data required for a server-side validation.
    public let dtas: String

    /// The public part of the user's signing key.
    public let publicKey: Data?

    public init(
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

    override public var description: String {
        "UserDTO(userId: \(userId), projectId: \(projectId), revoked: \(revoked), pinLength: \(pinLength), token: \(REDACTED_STRING), dtas: \(dtas), publicKey: \(String(describing: publicKey)))"
    }
}

extension UserDTO {
    func toUser() -> User {
        User(
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
