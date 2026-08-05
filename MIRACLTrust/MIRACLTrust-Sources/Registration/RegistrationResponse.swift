import Foundation

struct RegistrationResponse: Codable {
    var mpinId: String
    var projectId: String
    var designatedTAs: [DesignatedTA]
}
