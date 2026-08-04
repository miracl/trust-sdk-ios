@testable import MIRACLTrust
import XCTest

final class ConfigurationTests: XCTestCase {
    func testSDKCorrectConfiguration() throws {
        let applicationInfo = UUID().uuidString
        let projectId = UUID().uuidString

        let configuration = try XCTUnwrap(
            Configuration.Builder(projectId: projectId, projectURL: projectURL)
                .applicationInfo(applicationInfo: applicationInfo)
                .build()
        )
        try MIRACLTrust.configure(with: configuration)

        let configurationHeaders = try XCTUnwrap(MIRACLTrust.getInstance().urlSessionConfiguration.httpAdditionalHeaders)
        let miraclHeader = try XCTUnwrap(configurationHeaders["X-Miracl-Client"] as? String)
        let sdkVersion = try XCTUnwrap(Bundle(for: MIRACLTrust.self).infoDictionary?["CFBundleShortVersionString"])
        XCTAssertEqual(miraclHeader, "MIRACL iOS SDK/\(sdkVersion) \(applicationInfo)")

        let deviceTagHeader = try XCTUnwrap(configurationHeaders["X-Miracl-Device-Tag"] as? String)
        XCTAssertEqual(deviceTagHeader, MIRACLTrust.getInstance().deviceTagManager.deviceTag)

        let deviceName = try XCTUnwrap(configurationHeaders["X-Miracl-Device-Name"] as? String)
        XCTAssertEqual(deviceName, MIRACLTrust.getInstance().deviceName)
    }

    func testSDKEmptyProjectIdConfiguration() {
        let projectId = ""

        XCTAssertThrowsError(try Configuration.Builder(
            projectId: projectId,
            projectURL: projectURL
        ).build()) { error in
            XCTAssertTrue(error is ConfigurationError)
            XCTAssertEqual(error as? ConfigurationError, ConfigurationError.emptyProjectId)
        }
    }

    func testSDKInvalidProjectIdWithSpaceConfiguration() {
        let projectId = "       "

        XCTAssertThrowsError(try Configuration.Builder(
            projectId: projectId,
            projectURL: projectURL
        ).build()) { error in
            XCTAssertTrue(error is ConfigurationError)
            XCTAssertEqual(error as? ConfigurationError, ConfigurationError.emptyProjectId)
        }
    }

    func testSDKInvalidURLConfiguration() {
        let projectURL = ""

        XCTAssertThrowsError(try Configuration.Builder(
            projectId: UUID().uuidString,
            projectURL: projectURL
        ).build()) { error in
            XCTAssertTrue(error is ConfigurationError)
            XCTAssertEqual(error as? ConfigurationError, ConfigurationError.invalidProjectURL)
        }
    }

    func testSDKDifferentInvalidURLConfiguration() {
        let projectURL = "https://api. mpin. io "

        XCTAssertThrowsError(try Configuration.Builder(
            projectId: UUID().uuidString,
            projectURL: projectURL
        ).build()) { error in
            XCTAssertTrue(error is ConfigurationError)
            XCTAssertEqual(error as? ConfigurationError, ConfigurationError.invalidProjectURL)
        }
    }
}
