@testable import MIRACLTrust
import XCTest

class SessionDetailIntegrationTests: XCTestCase {
    let platformURL = ProcessInfo.processInfo.environment["platformURL"]!
    let projectId = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let testCase = SessionDetailsTestCase()

    var accessId = ""
    var qrCode = ""
    var pushNotificationsPayload = [AnyHashable: Any]()
    var universalLinkURL: URL?
    var api = PlatformAPIWrapper()

    let expectedProjectId = ProcessInfo.processInfo.environment["projectIdDV"]!
    let userId = "int@miracl.com"

    override func setUpWithError() throws {
        accessId = try XCTUnwrap(api.getAccessId(projectId: projectId))
        qrCode = "https://mcl.mpin.io#\(accessId)"
        universalLinkURL = URL(string: qrCode)
        pushNotificationsPayload = ["qrURL": qrCode]

        let platformURL = try XCTUnwrap(URL(string: platformURL))

        let configuration = try Configuration
            .Builder(projectId: projectId)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))
    }

    // MARK: Get Session details from QR code

    func testGetSessionDetailsQRCode() throws {
        let (details, error) = testCase.getSessionDetails(qrCode: qrCode)
        XCTAssertNil(error)
        XCTAssertNotNil(details)

        let expandedDetails = try XCTUnwrap(details)
        XCTAssertEqual(expandedDetails.projectId, projectId)
    }

    func testGetSessionDetailForDifferentProject() throws {
        accessId = try XCTUnwrap(api.getAccessId(projectId: expectedProjectId))
        qrCode = "https://mcl.mpin.io#\(accessId)"

        let (details, error) = testCase.getSessionDetails(qrCode: qrCode)
        XCTAssertNil(error)

        XCTAssertNotNil(details)
        let expandedDetails = try XCTUnwrap(details)
        XCTAssertEqual(expandedDetails.projectId, expectedProjectId)
    }

    func testGetSessionDetailForInvalidQRCode() {
        qrCode = "https://mcl.mpin.io#InvalidAccessId"

        let (details, error) = testCase.getSessionDetails(qrCode: qrCode)
        XCTAssertNil(details)

        // There is a bug on a platform.
        var isJsonError = false

        if case let .getAuthenticationSessionDetailsFail(cause) = error as? AuthenticationSessionError {
            if let cause, case .apiMalformedJSON = cause as? APIError {
                isJsonError = true
            }
        }
        XCTAssertTrue(isJsonError)
    }

    func testGetSessionDetailForEmptyQRCode() {
        let (details, error) = testCase.getSessionDetails(qrCode: "")
        XCTAssertNil(details)
        assertError(current: error, expected: AuthenticationSessionError.invalidQRCode)
    }

    // MARK: Get Session details from universal link URL

    func testGetSessionDetailsUniversalLinkURL() throws {
        let universalLinkURL = try XCTUnwrap(universalLinkURL)
        let (details, error) = testCase.getSessionDetails(universalLinkURL: universalLinkURL)
        XCTAssertNil(error)
        XCTAssertNotNil(details)

        let expandedDetails = try XCTUnwrap(details)
        XCTAssertEqual(expandedDetails.projectId, projectId)
    }

    func testGetSessionDetailsUniversalLinkURLForDifferentProject() throws {
        accessId = try XCTUnwrap(api.getAccessId(projectId: expectedProjectId))
        qrCode = "https://mcl.mpin.io#\(accessId)"
        let universalLinkURL = try XCTUnwrap(URL(string: qrCode))

        let (details, error) = testCase.getSessionDetails(universalLinkURL: universalLinkURL)
        XCTAssertNil(error)

        XCTAssertNotNil(details)
        let expandedDetails = try XCTUnwrap(details)
        XCTAssertEqual(expandedDetails.projectId, expectedProjectId)
    }

    func testGetSessionDetailsForMissingURLFragment() throws {
        qrCode = "https://mcl.mpin.io"
        let universalLinkURL = try XCTUnwrap(URL(string: qrCode))

        let (details, error) = testCase.getSessionDetails(universalLinkURL: universalLinkURL)
        XCTAssertNil(details)
        assertError(current: error, expected: AuthenticationSessionError.invalidUniversalLinkURL)
    }

    // MARK: Get Session details from push notifications payload

    func testGetSessionDetailsFromPushNotificationsPayload() throws {
        let (details, error) = testCase.getSessionDetails(payload: pushNotificationsPayload)
        XCTAssertNil(error)
        XCTAssertNotNil(details)

        let expandedDetails = try XCTUnwrap(details)
        XCTAssertEqual(expandedDetails.projectId, projectId)
    }

    func testGetSessionDetailsFromPushNotificationsPayloadMissingPayloadEntry() {
        pushNotificationsPayload = [AnyHashable: Any]()

        let (details, error) = testCase.getSessionDetails(payload: pushNotificationsPayload)
        XCTAssertNil(details)
        assertError(current: error, expected: AuthenticationSessionError.invalidPushNotificationPayload)
    }

    func testGetSessionDetailsFromPushNotificationsPayloadInvalidURL() {
        pushNotificationsPayload = [
            "qrURL": "InvalidURL"
        ]

        let (details, error) = testCase.getSessionDetails(payload: pushNotificationsPayload)
        XCTAssertNil(details)
        assertError(current: error, expected: AuthenticationSessionError.invalidPushNotificationPayload)
    }

    func testGetSessionDetailsFromPushNotificationsPayloadInvalidURLFragment() {
        pushNotificationsPayload = [
            "qrURL": "https://mcl.mpin.io#"
        ]

        let (details, error) = testCase.getSessionDetails(payload: pushNotificationsPayload)
        XCTAssertNil(details)
        assertError(current: error, expected: AuthenticationSessionError.invalidPushNotificationPayload)
    }
}
