struct APIErrorResponse: Codable {
    public var error: String
    public var info: String
    public var context: [String: String]?
}
