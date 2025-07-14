struct FallbackRequestErrorResponse: Codable {
    var requestID: String
    var error: FallbackErrorResponse
}

struct FallbackErrorResponse: Codable {
    var code: String
    var info: String
    var context: [String: String]?
}
