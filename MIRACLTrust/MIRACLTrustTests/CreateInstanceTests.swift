@_spi(MIRACLTrustAuthenticatorApi) @testable import MIRACLTrust
import XCTest

class CreateInstanceTests: XCTestCase {
    var projectId = UUID().uuidString
    var projectURL = "https://example.com/api/item/\(UUID().uuidString)"

    override func setUpWithError() throws {
        try super.setUpWithError()

        projectId = UUID().uuidString
        projectURL = "https://example.com/api/item/\(UUID().uuidString)"
    }

    func testCreateInstanceWithConfiguration() throws {
        let configuration = try Configuration.Builder().build()
        try MIRACLTrust.setDefaultConfiguration(configuration)

        let instance = try MIRACLTrust.createInstance(projectId: projectId, projectURL: projectURL)
        XCTAssertNotNil(instance)
        XCTAssertEqual(instance.projectId, projectId)
    }

    func testCreateInstanceWithoutConfiguration() throws {
        MIRACLTrust.configuration = nil

        let instance = try MIRACLTrust.createInstance(projectId: projectId, projectURL: projectURL)
        XCTAssertNotNil(instance)
        XCTAssertEqual(instance.projectId, projectId)
    }

    func testCreateInstanceWithCustomStorage() throws {
        let configuration = try Configuration
            .Builder()
            .userStorage(
                userStorage: MockUserStorage()
            ).build()
        try MIRACLTrust.setDefaultConfiguration(configuration)
        let instance = try MIRACLTrust.createInstance(projectId: projectId, projectURL: projectURL)

        XCTAssertNotNil(instance)
        XCTAssertEqual(instance.projectId, projectId)
        XCTAssertTrue(instance.userStorage is MockUserStorage)
    }
}
