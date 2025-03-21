@testable import MIRACLTrust
import XCTest

class SessionDetailsFetcherTests: XCTestCase {
    var accessId = ""
    var qrCode = ""
    var universalLinkURL: URL?
    var payload = [AnyHashable: Any]()
    var storage = MockUserStorage()
    var api = MockAPI()

    var randomString = UUID().uuidString
    var randomPin = Int.random(in: 1 ... 6)
    var sessionDetailResponse = AuthenticationSessionsDetailsResponse()

    override func setUpWithError() throws {
        accessId = "b227d0850d4280b98c5124a14aec84bf"
        qrCode = "https://mcl.mpin.io#\(accessId)"
        universalLinkURL = URL(string: qrCode)
        payload = ["qrURL": qrCode]

        sessionDetailResponse.prerollId = randomString
        sessionDetailResponse.projectId = randomString
        sessionDetailResponse.projectName = randomString
        sessionDetailResponse.projectLogoURL = randomString
        sessionDetailResponse.pinLength = randomPin
        sessionDetailResponse.verificationURL = randomString
        sessionDetailResponse.verificationMethod = "fullCustom"
        sessionDetailResponse.verificationCustomText = randomString
        sessionDetailResponse.identityTypeLabel = randomString
        sessionDetailResponse.identityType = "email"
        sessionDetailResponse.limitQuickCodeRegistration = true
        sessionDetailResponse.quickCodeEnabled = true

        api = MockAPI()
        api.sessionDetailsError = nil
        api.sessionDetailsResultCall = .success
        api.sessionDetailsResponse = sessionDetailResponse

        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString
            )
            .build()
        try MIRACLTrust.configure(with: configuration)
    }

    func testGetSessionDetailsQRCode() throws {
        let randomString = randomString
        let accessId = accessId
        let randomPin = randomPin

        getSessionDetailsFromQrCode { details, error in
            XCTAssertNil(error)
            assertSessionDetails(sessionDetails: details, randomString: randomString, accessId: accessId, randomPinLength: randomPin)
        }
    }

    func testGetSessionDetailsUniversalLinkURL() throws {
        let randomString = randomString
        let accessId = accessId
        let randomPin = randomPin

        getSessionDetailsFromUniversalLinkURL { details, error in
            XCTAssertNil(error)
            assertSessionDetails(sessionDetails: details, randomString: randomString, accessId: accessId, randomPinLength: randomPin)
        }
    }

    func testGetSessionDetailsPayload() throws {
        let randomString = randomString
        let accessId = accessId
        let randomPin = randomPin

        getSessionDetailsFromPayload { details, error in
            XCTAssertNil(error)
            assertSessionDetails(sessionDetails: details, randomString: randomString, accessId: accessId, randomPinLength: randomPin)
        }
    }

    func testGetSessionDetailsEmptyQRCode() {
        qrCode = "https://mcl.mpin.io"

        XCTAssertThrowsError(
            try AuthenticationSessionDetailsFetcher(
                qrCode: qrCode,
                miraclAPI: api,
                completionHandler: { _, _ in }
            ),
            "Error when creating detail fetcher"
        ) { error in
            assertError(
                current: error,
                expected: AuthenticationSessionError.invalidQRCode
            )
        }
    }

    func testGetSessionDetailsEmptyUniversalLinkURL() throws {
        let universalLinkURL = try XCTUnwrap(URL(string: "https://mcl.mpin.io"))

        XCTAssertThrowsError(
            try AuthenticationSessionDetailsFetcher(
                universalLinkURL: universalLinkURL,
                miraclAPI: api,
                completionHandler: { _, _ in }
            ),
            "Error when creating detail fetcher"
        ) { error in
            assertError(
                current: error,
                expected: AuthenticationSessionError.invalidUniversalLinkURL
            )
        }
    }

    func testGetSessionDetailsEmptyPushNotificationsPayload() {
        payload = ["qrURL": "https://mcl.mpin.io"]

        XCTAssertThrowsError(
            try AuthenticationSessionDetailsFetcher(
                pushNotificationsPayload: payload,
                miraclAPI: api,
                completionHandler: { _, _ in }
            ),
            "Error when creating detail fetcher"
        ) { error in
            assertError(
                current: error,
                expected: AuthenticationSessionError.invalidPushNotificationPayload
            )
        }
    }

    func testGetSessionDetailsServerError() {
        let cause = APIError.apiServerError(statusCode: 500, message: nil, requestURL: nil)
        let expectedError = AuthenticationSessionError.getAuthenticationSessionDetailsFail(cause)

        api.sessionDetailsError = cause
        api.sessionDetailsResultCall = .failed
        api.sessionDetailsResponse = nil

        getSessionDetailsFromQrCode { detail, error in
            XCTAssertNil(detail)
            assertError(
                current: error,
                expected: expectedError
            )
        }
    }

    func testGetSessionDetailsNilResponse() {
        let desiredError = AuthenticationSessionError.getAuthenticationSessionDetailsFail(nil)

        api.sessionDetailsError = nil
        api.sessionDetailsResultCall = .failed
        api.sessionDetailsResponse = nil

        getSessionDetailsFromQrCode { detail, error in
            XCTAssertNil(detail)
            assertError(
                current: error,
                expected: desiredError
            )
        }
    }

    // MARK: Private

    private func getSessionDetailsFromQrCode(completionHandler: @escaping AuthenticationSessionDetailsCompletionHandler) {
        let waitForSession = XCTestExpectation(description: "Wait for getSessionDetails to finish")

        do {
            let sessionDetailsFetcher = try AuthenticationSessionDetailsFetcher(
                qrCode: qrCode,
                miraclAPI: api
            ) { details, error in
                completionHandler(details, error)
                waitForSession.fulfill()
            }
            sessionDetailsFetcher.fetch()

            let waitResult = XCTWaiter.wait(for: [waitForSession], timeout: 10.0)
            if waitResult != .completed {
                XCTFail("Failed expectation")
            }
        } catch {
            XCTFail("Error in session detail creation: \(error)")
        }
    }

    private func getSessionDetailsFromUniversalLinkURL(completionHandler: @escaping AuthenticationSessionDetailsCompletionHandler) {
        let waitForSession = XCTestExpectation(description: "Wait for getSessionDetails to finish")

        do {
            let url = try XCTUnwrap(universalLinkURL)
            let sessionDetailsFetcher = try AuthenticationSessionDetailsFetcher(
                universalLinkURL: url,
                miraclAPI: api
            ) { details, error in
                completionHandler(details, error)
                waitForSession.fulfill()
            }
            sessionDetailsFetcher.fetch()

            let waitResult = XCTWaiter.wait(for: [waitForSession], timeout: 10.0)
            if waitResult != .completed {
                XCTFail("Failed expectation")
            }
        } catch {
            XCTFail("Error in session detail creation: \(error)")
        }
    }

    private func getSessionDetailsFromPayload(completionHandler: @escaping AuthenticationSessionDetailsCompletionHandler) {
        let waitForSession = XCTestExpectation(description: "Wait for getSessionDetails to finish")

        do {
            let url = try XCTUnwrap(universalLinkURL)
            let sessionDetailsFetcher = try AuthenticationSessionDetailsFetcher(
                universalLinkURL: url,
                miraclAPI: api
            ) { details, error in
                completionHandler(details, error)
                waitForSession.fulfill()
            }
            sessionDetailsFetcher.fetch()

            let waitResult = XCTWaiter.wait(for: [waitForSession], timeout: 10.0)
            if waitResult != .completed {
                XCTFail("Failed expectation")
            }
        } catch {
            XCTFail("Error in session detail creation: \(error)")
        }
    }
}
