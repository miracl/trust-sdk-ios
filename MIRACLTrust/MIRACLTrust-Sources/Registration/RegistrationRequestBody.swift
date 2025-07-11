struct RegistrationRequestBody: Codable {
    var userId: String
    var deviceName: String
    var activationToken: String
    var publicKey: String
    var pushToken: String?
}
