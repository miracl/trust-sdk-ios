struct CrossDeviceSessionResponse: Codable {
    var prerollId: String
    var projectId: String
    var signingHash: String
    var sessionDescription: String

    enum CodingKeys: String, CodingKey {
        case prerollId
        case projectId
        case signingHash = "hash"
        case sessionDescription = "description"
    }
}
