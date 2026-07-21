struct VerificationRequestBody: Codable {
    var projectId: String
    var userId: String
    var deviceName: String
    var deviceTag: String
    var accessId: String?
    var mpinId: String?
}
