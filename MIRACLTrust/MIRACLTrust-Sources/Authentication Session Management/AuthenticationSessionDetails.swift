import Foundation

/// Object representing details from incoming authentication session.
@objcMembers
@objc public final class AuthenticationSessionDetails: NSObject, SessionDetails, Sendable {
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

    /// Identifier of the authentication session.
    public let accessId: String

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
        accessId: String
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
        self.accessId = accessId
    }
}
