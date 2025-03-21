@testable import MIRACLTrust
import XCTest

final class ConfigurationTests: XCTestCase {
    private var baseURL = URL(string: "https://api.mpin.io")!

    func testSDKCorrectConfiguration() throws {
        let applicationInfo = UUID().uuidString

        guard let configuration = try? Configuration.Builder(
            projectId: "mockedProjectId"
        ).platformURL(url: baseURL)
            .applicationInfo(applicationInfo: applicationInfo)
            .build() else {
            XCTFail("Fail at \(#function) on row \(#line)")
            return
        }

        do {
            try MIRACLTrust.configure(with: configuration)
        } catch {
            XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
        }

        do {
            let configurationHeaders = try XCTUnwrap(MIRACLTrust.getInstance().urlSessionConfiguration.httpAdditionalHeaders)
            let miraclHeader = try XCTUnwrap(configurationHeaders["X-MIRACL-CLIENT"] as? String)
            let sdkVersion = try XCTUnwrap(Bundle(for: MIRACLTrust.self).infoDictionary?["CFBundleShortVersionString"])
            XCTAssertEqual(miraclHeader, "MIRACL iOS SDK/\(sdkVersion) \(applicationInfo)")
        } catch {
            XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
        }
    }

    func testSDKEmptyProjectIdConfiguration() {
        let projectId = ""

        XCTAssertThrowsError(try Configuration.Builder(
            projectId: projectId
        ).build()) { error in
            XCTAssertTrue(error is ConfigurationError)
            XCTAssertEqual(error as? ConfigurationError, ConfigurationError.configurationEmptyProjectId)
        }
    }

    func testSDKInvalidProjectIdWithSpaceConfiguration() {
        let projectId = "       "

        XCTAssertThrowsError(try Configuration.Builder(
            projectId: projectId).build()
        ) { error in
            XCTAssertTrue(error is ConfigurationError)
            XCTAssertEqual(error as? ConfigurationError, ConfigurationError.configurationEmptyProjectId)
        }
    }
}
