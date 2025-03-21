import Foundation

/**
 HTTP response object received in a completion block after a call to [pass1](x-source-tag://API-_FUNC_pass1formpinidpublickeyuvaluescopecompletionhandler) method of the [API](x-source-tag://API) class.
 */
struct Pass1Response: Codable {
    /// Random number received from the MIRACL platform.
    var challenge = ""

    enum CodingKeys: String, CodingKey {
        case challenge = "y"
    }
}
