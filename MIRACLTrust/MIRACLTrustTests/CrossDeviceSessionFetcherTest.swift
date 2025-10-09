@testable import MIRACLTrust
import XCTest

final class CrossDeviceSessionFetcherTest: XCTestCase {
    let sessionTimeout = 10.0

    var sessionId = ""
    var qrCode = ""
    var universalLinkURL: URL?
    var payload = [AnyHashable: Any]()
    var api = MockAPI()
    var randomString = UUID().uuidString
    var randomPin = Int.random(in: 1 ... 6)

    var crossDeviceSessionResponse: CrossDeviceSessionResponse!

    override func setUpWithError() throws {
        try super.setUpWithError()

        sessionId = "b227d0850d4280b98c5124a14aec84bf"
        qrCode = "https://mcl.mpin.io#\(sessionId)"
        universalLinkURL = URL(string: qrCode)
        payload = ["qrURL": qrCode]
        randomString = UUID().uuidString

        crossDeviceSessionResponse = CrossDeviceSessionResponse(
            prerollId: randomString,
            projectId: randomString,
            projectName: randomString,
            projectLogoURL: randomString,
            pinLength: randomPin,
            verificationMethod: "fullCustom",
            verificationURL: randomString,
            verificationCustomText: randomString,
            identityTypeLabel: randomString,
            identityType: "email",
            quickCodeEnabled: true,
            signingHash: randomString,
            sessionDescription: randomString
        )

        api = MockAPI()
        api.crossDeviceSessionError = nil
        api.crossDeviceSessionResultCall = .success
        api.crossDeviceSessionResponse = crossDeviceSessionResponse

        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString,
                projectURL: projectURL
            )
            .build()
        try MIRACLTrust.configure(with: configuration)
    }

    func testGetCrossDeviceSessionFromQRCode() throws {
        let sessionId = sessionId
        let randomPin = randomPin

        getCrossDeviceSessionFromQrCode { details, error in
            XCTAssertNil(error)
            self.assertSessionDetails(crossDeviceSession: details, sessionId: sessionId, randomPinLength: randomPin)
        }
    }

    func testGetSessionDetailsUniversalLinkURL() throws {
        let sessionId = sessionId
        let randomPin = randomPin

        getCrossDeviceSessionFromUniversalLinkURL { details, error in
            XCTAssertNil(error)
            self.assertSessionDetails(crossDeviceSession: details, sessionId: sessionId, randomPinLength: randomPin)
        }
    }

    func testGetSessionDetailsPayload() throws {
        let sessionId = sessionId
        let randomPin = randomPin

        getCrossDeviceSessionFromPayload { details, error in
            XCTAssertNil(error)
            self.assertSessionDetails(crossDeviceSession: details, sessionId: sessionId, randomPinLength: randomPin)
        }
    }

    func testCrossDeviceSessionEmptyQRCode() {
        qrCode = "https://mcl.mpin.io"

        XCTAssertThrowsError(
            try CrossDeviceSessionFetcher(qrCode: qrCode, miraclAPI: api, completionHandler: { _, _ in }),
            "Error when creating detail fetcher"
        ) { error in
            assertError(
                current: error,
                expected: CrossDeviceSessionError.invalidQRCode
            )
        }
    }

    func testCrossDeviceSessionEmptyUniversalLinkURL() throws {
        let universalLinkURL = try XCTUnwrap(URL(string: "https://mcl.mpin.io"))

        XCTAssertThrowsError(
            try CrossDeviceSessionFetcher(universalLinkURL: universalLinkURL, miraclAPI: api, completionHandler: { _, _ in }),
            "Error when creating detail fetcher"
        ) { error in
            assertError(
                current: error,
                expected: CrossDeviceSessionError.invalidUniversalLinkURL
            )
        }
    }

    func testCrossDeviceSessionEmptyPushNotificationsPayload() {
        payload = ["qrURL": "https://mcl.mpin.io"]

        XCTAssertThrowsError(
            try CrossDeviceSessionFetcher(pushNotificationPayload: payload, miraclAPI: api, completionHandler: { _, _ in }),
            "Error when creating detail fetcher"
        ) { error in
            assertError(
                current: error,
                expected: CrossDeviceSessionError.invalidPushNotificationPayload
            )
        }
    }

    func testGetSessionDetailsServerError() {
        let cause = APIError.apiServerError(statusCode: 500, message: nil, requestURL: nil)
        let expectedError = CrossDeviceSessionError.getCrossDeviceSessionFail(cause)

        api.crossDeviceSessionError = cause
        api.crossDeviceSessionResultCall = .failed
        api.sessionDetailsResponse = nil

        getCrossDeviceSessionFromQrCode { detail, error in
            XCTAssertNil(detail)
            assertError(
                current: error,
                expected: expectedError
            )
        }
    }

    func testGetSessionDetailsNilResponse() {
        let desiredError = CrossDeviceSessionError.getCrossDeviceSessionFail(nil)

        api.crossDeviceSessionError = nil
        api.crossDeviceSessionResultCall = .failed
        api.crossDeviceSessionResponse = nil

        getCrossDeviceSessionFromQrCode { detail, error in
            XCTAssertNil(detail)
            assertError(
                current: error,
                expected: desiredError
            )
        }
    }

    // MARK: Private

    private func getCrossDeviceSessionFromQrCode(completionHandler: @escaping CrossDeviceSessionCompletionHandler) {
        let waitForSession = XCTestExpectation(description: "Wait for getSessionDetails to finish")

        do {
            let crossDeviceSessionFetcher = try CrossDeviceSessionFetcher(
                qrCode: qrCode,
                miraclAPI: api
            ) { session, error in
                completionHandler(session, error)
                waitForSession.fulfill()
            }
            crossDeviceSessionFetcher.fetch()

            let waitResult = XCTWaiter.wait(for: [waitForSession], timeout: sessionTimeout)
            if waitResult != .completed {
                XCTFail("Failed expectation")
            }
        } catch {
            XCTFail("Error in session detail creation: \(error)")
        }
    }

    private func getCrossDeviceSessionFromUniversalLinkURL(completionHandler: @escaping CrossDeviceSessionCompletionHandler) {
        let waitForSession = XCTestExpectation(description: "Wait for getSessionDetails to finish")

        do {
            let url = try XCTUnwrap(universalLinkURL)

            let crossDeviceSessionFetcher = try CrossDeviceSessionFetcher(
                universalLinkURL: url,
                miraclAPI: api
            ) { session, error in
                completionHandler(session, error)
                waitForSession.fulfill()
            }
            crossDeviceSessionFetcher.fetch()

            let waitResult = XCTWaiter.wait(for: [waitForSession], timeout: sessionTimeout)
            if waitResult != .completed {
                XCTFail("Failed expectation")
            }
        } catch {
            XCTFail("Error in session detail creation: \(error)")
        }
    }

    private func getCrossDeviceSessionFromPayload(completionHandler: @escaping CrossDeviceSessionCompletionHandler) {
        let waitForSession = XCTestExpectation(description: "Wait for getSessionDetails to finish")

        do {
            let crossDeviceSessionFetcher = try CrossDeviceSessionFetcher(
                pushNotificationPayload: payload,
                miraclAPI: api
            ) { session, error in
                completionHandler(session, error)
                waitForSession.fulfill()
            }
            crossDeviceSessionFetcher.fetch()

            let waitResult = XCTWaiter.wait(for: [waitForSession], timeout: sessionTimeout)
            if waitResult != .completed {
                XCTFail("Failed expectation")
            }
        } catch {
            XCTFail("Error in session detail creation: \(error)")
        }
    }

    private func assertSessionDetails(
        crossDeviceSession: CrossDeviceSession?,
        sessionId: String,
        randomPinLength: Int
    ) {
        do {
            let fetchedDetails = try XCTUnwrap(crossDeviceSession)

            XCTAssertEqual(fetchedDetails.userId, randomString)
            XCTAssertEqual(fetchedDetails.projectId, randomString)
            XCTAssertEqual(fetchedDetails.projectName, randomString)
            XCTAssertEqual(fetchedDetails.projectLogoURL, randomString)
            XCTAssertEqual(fetchedDetails.sessionId, sessionId)
            XCTAssertEqual(fetchedDetails.pinLength, randomPinLength)
            XCTAssertEqual(fetchedDetails.verificationMethod, .fullCustom)
            XCTAssertEqual(fetchedDetails.verificationURL, randomString)
            XCTAssertEqual(fetchedDetails.identityTypeLabel, randomString)
            XCTAssertEqual(fetchedDetails.verificationCustomText, randomString)
            XCTAssertEqual(fetchedDetails.identityType, IdentityType.email)
            XCTAssertEqual(fetchedDetails.quickCodeEnabled, true)

        } catch {
            XCTFail("Get session detail failed")
        }
    }
}
