import Foundation

struct RegistrationResponse: Codable {
    var mpinId: String
    var projectId: String
    var dtas: String
    var curve: String
    var secretUrls: [String]
}
