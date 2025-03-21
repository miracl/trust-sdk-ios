import Foundation

/**
 HTTP response object received in а completion block after a call to a [signature](x-source-tag://API-_FUNC_signatureforregottcompletionhandler) method of the [API](x-source-tag://API) class.
 */
struct SignatureResponse: Codable {
    var dvsClientSecretShare: String = ""

    /// The URL where the second client secret share will be retrieved from.
    var cs2URL: URL?

    /// Elliptic curve used in the crypto library.
    var curve: String = ""

    /// Base64 encoded string containing DTA-s.
    var dtas: String = ""

    enum CodingKeys: String, CodingKey {
        case dvsClientSecretShare
        case cs2URL = "cs2url"
        case curve
        case dtas
    }
}
