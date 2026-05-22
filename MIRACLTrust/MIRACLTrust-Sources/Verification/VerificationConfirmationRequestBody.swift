struct VerificationConfirmationRequestBody: Codable {
    var userId: String
    var code: String
    var deviceTag: String
}
