struct SigningSessionUpdaterRequestBody: Codable {
    var id: String
    var signature: Signature
    var timestamp: Int64
}
