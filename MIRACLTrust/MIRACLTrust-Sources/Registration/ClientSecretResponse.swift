import Foundation

/**
 HTTP response object received in а completion block after а call to [getClientSecret2](x-source-tag://API-_FUNC_getclientsecret2forcompletionhandler) method of the [API](x-source-tag://API) class.
 */
struct ClientSecretResponse: Codable {
    /// Second client share that will be combined with first client share.
    var dvsClientSecret = ""

    enum CodingKeys: String, CodingKey {
        case dvsClientSecret
    }
}
