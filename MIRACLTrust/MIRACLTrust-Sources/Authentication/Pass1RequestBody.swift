class Pass1RequestBody: Codable {
    var dtas: String = ""
    var mpinId: String = ""
    var uValue: String = ""
    var scope: [String] = []
    var publicKey: String?

    enum CodingKeys: String, CodingKey {
        case mpinId = "mpin_id"
        case dtas
        case uValue = "U"
        case scope
        case publicKey
    }
}
