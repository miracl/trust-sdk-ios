import Foundation

/// Object representing details from incoming signing session.
@objcMembers
@objc public final class SigningSessionDetails: NSObject, SessionDetails, Sendable {
    public let userId: String

    public let projectName: String

    public let projectLogoURL: String

    public let projectId: String

    public let pinLength: Int

    public let verificationMethod: VerificationMethod

    public let verificationURL: String

    public let verificationCustomText: String

    public let identityTypeLabel: String

    public let quickCodeEnabled: Bool

    public let limitQuickCodeRegistration: Bool

    public let identityType: IdentityType

    /// Identifier of the signing session.
    public let sessionId: String

    /// Hash of the transaction that needs to be signed.
    public let signingHash: String

    /// Description of the transaction that needs to be signed.
    public let signingDescription: String

    /// Status of the session.
    public let status: SigningSessionStatus

    /// Date indicating if session is expired
    public let expireTime: Date

    init(
        userId: String,
        projectName: String,
        projectLogoURL: String,
        projectId: String,
        pinLength: Int,
        verificationMethod: VerificationMethod,
        verificationURL: String,
        verificationCustomText: String,
        identityTypeLabel: String,
        quickCodeEnabled: Bool,
        limitQuickCodeRegistration: Bool,
        identityType: IdentityType,
        sessionId: String,
        signingHash: String,
        signingDescription: String,
        status: SigningSessionStatus,
        expireTime: Date
    ) {
        self.userId = userId
        self.projectName = projectName
        self.projectLogoURL = projectLogoURL
        self.projectId = projectId
        self.pinLength = pinLength
        self.verificationMethod = verificationMethod
        self.verificationURL = verificationURL
        self.verificationCustomText = verificationCustomText
        self.identityTypeLabel = identityTypeLabel
        self.quickCodeEnabled = quickCodeEnabled
        self.limitQuickCodeRegistration = limitQuickCodeRegistration
        self.identityType = identityType
        self.sessionId = sessionId
        self.signingHash = signingHash
        self.signingDescription = signingDescription
        self.status = status
        self.expireTime = expireTime
    }
}
