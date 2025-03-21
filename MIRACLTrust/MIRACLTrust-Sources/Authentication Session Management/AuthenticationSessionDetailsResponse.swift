struct AuthenticationSessionsDetailsResponse: Codable {
    var prerollId = ""
    var projectId = ""
    var projectName = ""
    var projectLogoURL = ""
    var pinLength = 0
    var verificationMethod = ""
    var verificationURL = ""
    var verificationCustomText = ""
    var identityTypeLabel = ""
    var identityType = ""
    var quickCodeEnabled = false
    var limitQuickCodeRegistration = false

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
    }
}
