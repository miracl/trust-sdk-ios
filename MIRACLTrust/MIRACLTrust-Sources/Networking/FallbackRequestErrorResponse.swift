struct FallbackRequestErrorResponse: Codable {
    var requestID: String
    var error: FallbackErrorResponse
}

struct FallbackErrorResponse: Codable {
    public var code: String
    public var info: String
    public var context: [String: String]?
}
