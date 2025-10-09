import Foundation

/// An object representing details for an operation (authentication or signing)  started on another device.
@objcMembers
@objc public final class CrossDeviceSession: NSObject, Sendable {
    /// User ID entered by the user when session is started.
    public let userId: String

    /// Name of the project in MIRACL Trust platform.
    public let projectName: String

    /// URL of the project logo.
    public let projectLogoURL: String

    /// Project ID setting for the application in MIRACL Trust platform.
    public let projectId: String

    /// PIN length that needs to be entered from the user.
    public let pinLength: Int

    /// Indicates method of user verification.
    public let verificationMethod: VerificationMethod

    /// URL for verification in case of custom verification method.
    public let verificationURL: String

    /// Custom text specified in the MIRACL Trust portal for the custom verification.
    public let verificationCustomText: String

    /// Label of the identity which will be used for identity verification.
    public let identityTypeLabel: String

    /// Indicates whether [QuickCode](https://miracl.com/resources/docs/guides/built-in-user-verification/quickcode/) is enabled for the project or not.
    public let quickCodeEnabled: Bool

    /// Identity type which will be used for identity verification.
    public let identityType: IdentityType

    /// Identifier of the session.
    public let sessionId: String

    /// Description of the operation that needs to be done.
    public let sessionDescription: String

    /// Hash of the transaction that needs to be signed if any.
    public let signingHash: String

    public init(
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
        identityType: IdentityType,
        sessionId: String,
        sessionDescription: String,
        signingHash: String
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
        self.identityType = identityType
        self.sessionId = sessionId
        self.sessionDescription = sessionDescription
        self.signingHash = signingHash
    }
}
