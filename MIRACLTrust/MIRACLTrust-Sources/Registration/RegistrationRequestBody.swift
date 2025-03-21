class RegistrationRequestBody: Codable {
    var userId: String = ""
    var deviceName: String = ""
    var activateCode: String = ""
    var pushToken: String?
}
