struct APIErrorResponse: Codable {
    var error: String
    var info: String
    var context: [String: String]?
}
