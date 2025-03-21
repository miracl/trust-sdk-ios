import Foundation

struct AuthenticateResponse: Codable {
    var jwt: String?
    var renewSecretResponse: RenewSecretResponse?

    enum CodingKeys: String, CodingKey {
        case renewSecretResponse = "dvsRegister"
        case jwt
    }
}

struct RenewSecretResponse: Codable {
    var token: String?
    var curve: String?
}
