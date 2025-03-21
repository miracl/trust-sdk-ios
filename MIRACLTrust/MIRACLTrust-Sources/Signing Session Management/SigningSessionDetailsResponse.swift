struct SigningSessionDetailsResponse: Codable {
    var userID: String
    var signingHash: String
    var signingDescription: String
    var status: String
    var expireTime: Int64
    var projectId: String
    var projectName: String
    var projectLogoURL: String
    var verificationMethod: String
    var verificationURL: String
    var verificationCustomText: String
    var identityType: String
    var identityTypeLabel: String
    var pinLength: Int
    var enableRegistrationCode: Bool
    var limitRegCodeVerified: Bool

    enum CodingKeys: String, CodingKey {
        case userID
        case signingHash = "hash"
        case signingDescription = "description"
        case status
        case expireTime
        case projectId
        case projectName
        case projectLogoURL
        case verificationMethod
        case verificationURL
        case verificationCustomText
        case identityType
        case identityTypeLabel
        case pinLength
        case enableRegistrationCode
        case limitRegCodeVerified
    }
}
