// Structure for `token.json`
struct Token: Codable {
    let accessToken: String
    let refreshToken: String?
    let scope: String = "https://www.googleapis.com/auth/gmail.readonly"
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}
