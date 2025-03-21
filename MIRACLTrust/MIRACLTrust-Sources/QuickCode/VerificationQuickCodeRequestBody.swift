import Foundation

struct VerificationQuickCodeRequestBody: Codable {
    var projectId: String
    var jwt: String
    var deviceName: String
}
