@testable import MIRACLTrust
import XCTest

class UpdateProjectSettingsIntegrationTests: XCTestCase {
    let projectId = ProcessInfo.processInfo.environment["projectIdDV"]!
    let platformURL = ProcessInfo.processInfo.environment["platformURL"]!

    override func setUpWithError() throws {
        let platformURL = try XCTUnwrap(URL(string: platformURL))

        let configuration = try Configuration
            .Builder(projectId: projectId)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))
    }

    func testUpdateProjectSettings() throws {
        let expectedProjectId = ProcessInfo.processInfo.environment["projectIdCUV"]!

        try MIRACLTrust.getInstance()
            .setProjectId(projectId: expectedProjectId)
        XCTAssertEqual(expectedProjectId, MIRACLTrust.getInstance().projectId)
    }

    func testUpdateProjectSettingsEmptyProjectId() {
        XCTAssertThrowsError(
            try MIRACLTrust.getInstance()
                .setProjectId(projectId: ""),
            "Error not thrown when project Id is empty"
        ) { error in
            assertError(current: error, expected: ConfigurationError.configurationEmptyProjectId)
        }
    }
}
