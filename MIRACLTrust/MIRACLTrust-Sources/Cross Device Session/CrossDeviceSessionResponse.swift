struct CrossDeviceSessionResponse: Codable {
    var prerollId: String
    var projectId: String
    var projectName: String
    var projectLogoURL: String
    var pinLength: Int
    var verificationMethod: String
    var verificationURL: String
    var verificationCustomText: String
    var identityTypeLabel: String
    var identityType: String
    var quickCodeEnabled: Bool
    var limitQuickCodeRegistration: Bool
    var signingHash: String
    var sessionDescription: String

    enum CodingKeys: String, CodingKey {
        case prerollId
        case projectId
        case projectName
        case projectLogoURL
        case pinLength
        case verificationMethod
        case verificationURL
        case verificationCustomText
        case identityTypeLabel
        case identityType
        case quickCodeEnabled = "enableRegistrationCode"
        case limitQuickCodeRegistration = "limitRegCodeVerified"
        case signingHash = "hash"
        case sessionDescription = "description"
    }
}
