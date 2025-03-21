import Foundation

/**
 HTTP response object received in a completion block after a call to [signingClientSecret1](x-source-tag://API-_FUNC_signingclientsecret1publickeysigningregistrationtokendevicenamecompletionhandler) method of the [API](x-source-tag://API) class.
 */
struct SigningClientSecret1Response: Codable {
    /// First signing client secret share.
    var signingClientSecretShare: String = ""

    /// The URL where the second signing client secret share will be retrieved from.
    var cs2URL: URL?

    /// Elliptic curve used in the crypto library.
    var curve: String = ""

    /// Base64 encoded string containing DTA-s.
    var dtas: String = ""

    /// Identity identifier.
    var mpinId: String = ""

    enum CodingKeys: String, CodingKey {
        case signingClientSecretShare = "dvsClientSecretShare"
        case cs2URL = "cs2url"
        case curve
        case dtas
        case mpinId
    }
}
