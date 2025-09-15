@testable import MIRACLTrust
import XCTest

class UpdateProjectSettingsIntegrationTests: XCTestCase {
    let projectId = ProcessInfo.processInfo.environment["projectIdDV"]!
    let projectURLDV = ProcessInfo.processInfo.environment["projectURLDV"]!
    let projectURLCV = ProcessInfo.processInfo.environment["projectURLCUV"]!

    override func setUpWithError() throws {
        let configuration = try Configuration
            .Builder(projectId: projectId, projectURL: projectURLDV)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))
    }

    func testUpdateProjectSettings() throws {
        let expectedProjectId = ProcessInfo.processInfo.environment["projectIdCUV"]!

        try MIRACLTrust.getInstance()
            .updateProjectSettings(
                projectId: expectedProjectId,
                projectURL: projectURLCV
            )
        XCTAssertEqual(expectedProjectId, MIRACLTrust.getInstance().projectId)
    }

    func testUpdateProjectSettingsEmptyProjectId() {
        XCTAssertThrowsError(
            try MIRACLTrust.getInstance()
                .updateProjectSettings(projectId: "", projectURL: projectURLCV),
            "Error not thrown when project Id is empty"
        ) { error in
            assertError(current: error, expected: ConfigurationError.emptyProjectId)
        }
    }

    func testUpdateProjectSettingsEmptyProjectURL() {
        XCTAssertThrowsError(
            try MIRACLTrust.getInstance()
                .updateProjectSettings(projectId: projectId, projectURL: ""),
            "Error not thrown when project URL is empty"
        ) { error in
            assertError(current: error, expected: ConfigurationError.invalidProjectURL)
        }
    }

    func testUpdateProjectSettingsInvalidProjectURL() {
        XCTAssertThrowsError(
            try MIRACLTrust.getInstance()
                .updateProjectSettings(projectId: projectId, projectURL: "https:// example .com. "),
            "Error not thrown when project URL is invalid"
        ) { error in
            assertError(current: error, expected: ConfigurationError.invalidProjectURL)
        }
    }

    func testSetProjectId() throws {
        let expectedProjectId = ProcessInfo.processInfo.environment["projectIdCUV"]!

        try MIRACLTrust.getInstance().setProjectId(projectId: expectedProjectId)

        XCTAssertEqual(expectedProjectId, MIRACLTrust.getInstance().projectId)
    }

    func testSetEmptyProjectId() {
        XCTAssertThrowsError(
            try MIRACLTrust.getInstance().setProjectId(projectId: ""),
            "Error not thrown when project Id is empty"
        ) { error in
            assertError(current: error, expected: ConfigurationError.emptyProjectId)
        }
    }
}
