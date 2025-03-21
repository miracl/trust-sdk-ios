class Pass2RequestBody: Codable {
    var mpinId = ""
    var vValue = ""
    var accessId: String?

    enum CodingKeys: String, CodingKey {
        case mpinId = "mpin_id"
        case vValue = "V"
        case accessId = "WID"
    }
}
