import Foundation

struct VerificationQuickCodeResponse: Codable {
    var code: String
    var expireTime: Date
    var ttlSeconds: Int
}
