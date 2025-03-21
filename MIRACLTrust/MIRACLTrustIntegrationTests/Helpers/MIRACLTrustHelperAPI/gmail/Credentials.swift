// Structure for `credentials.json`

struct Installed: Codable {
    let clientID: String
    let projectID: String
    let authURI: String
    let tokenURI: String
    let authProviderX509CertURL: String
    let clientSecret: String
    let redirectURIs: [String]

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case projectID = "project_id"
        case authURI = "auth_uri"
        case tokenURI = "token_uri"
        case authProviderX509CertURL = "auth_provider_x509_cert_url"
        case clientSecret = "client_secret"
        case redirectURIs = "redirect_uris"
    }
}

struct Credentials: Codable {
    let installed: Installed
}
