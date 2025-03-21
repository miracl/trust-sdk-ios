import Foundation

struct VerificationRequestResponse: Codable {
    var backoff: Int64
    var method: String
}
