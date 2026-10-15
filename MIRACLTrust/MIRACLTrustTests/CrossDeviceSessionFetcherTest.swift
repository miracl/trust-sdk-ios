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
    var logger = DefaultLogger(level: .none)

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

    @MainActor
    func testGetCrossDeviceSessionFromQRCode() {
        let sessionId = sessionId

        getCrossDeviceSessionFromQrCode { result in
            do {
                let details = try result.get()
                self.assertSessionDetails(crossDeviceSession: details, sessionId: sessionId)
            } catch {
                XCTFail("Expected .success, but got \(result)")
            }
        }
    }

    @MainActor
    func testGetSessionDetailsUniversalLinkURL() {
        let sessionId = sessionId

        getCrossDeviceSessionFromUniversalLinkURL { result in
            do {
                let details = try result.get()
                self.assertSessionDetails(crossDeviceSession: details, sessionId: sessionId)
            } catch {
                XCTFail("Expected .success, but got \(result)")
            }
        }
    }

    @MainActor
    func testGetSessionDetailsPayload() {
        let sessionId = sessionId

        getCrossDeviceSessionFromPayload { result in
            do {
                let details = try result.get()
                self.assertSessionDetails(crossDeviceSession: details, sessionId: sessionId)
            } catch {
                XCTFail("Expected .success, but got \(result)")
            }
        }
    }

    func testCrossDeviceSessionEmptyQRCode() {
        qrCode = "https://mcl.mpin.io"

        XCTAssertThrowsError(
            try CrossDeviceSessionFetcher(qrCode: qrCode, miraclAPI: api, logger: logger, completionHandler: { _ in }),
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
            try CrossDeviceSessionFetcher(universalLinkURL: universalLinkURL, miraclAPI: api, logger: logger, completionHandler: { _ in }),
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
            try CrossDeviceSessionFetcher(pushNotificationPayload: payload, miraclAPI: api, logger: logger, completionHandler: { _ in }),
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

        getCrossDeviceSessionFromQrCode { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected .failure, but got \(result)")
                return
            }
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

        getCrossDeviceSessionFromQrCode { result in
            guard case let .failure(error) = result else {
                XCTFail("Expected .failure, but got \(result)")
                return
            }
            assertError(
                current: error,
                expected: desiredError
            )
        }
    }

    // MARK: Private

    private func getCrossDeviceSessionFromQrCode(completionHandler: @escaping CrossDeviceSessionResultCompletionHandler) {
        let waitForSession = XCTestExpectation(description: "Wait for getSessionDetails to finish")

        do {
            let crossDeviceSessionFetcher = try CrossDeviceSessionFetcher(
                qrCode: qrCode,
                miraclAPI: api,
                logger: logger
            ) { result in
                completionHandler(result)
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

    private func getCrossDeviceSessionFromUniversalLinkURL(completionHandler: @escaping CrossDeviceSessionResultCompletionHandler) {
        let waitForSession = XCTestExpectation(description: "Wait for getSessionDetails to finish")

        do {
            let url = try XCTUnwrap(universalLinkURL)

            let crossDeviceSessionFetcher = try CrossDeviceSessionFetcher(
                universalLinkURL: url,
                miraclAPI: api,
                logger: logger
            ) { result in
                completionHandler(result)
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

    private func getCrossDeviceSessionFromPayload(completionHandler: @escaping CrossDeviceSessionResultCompletionHandler) {
        let waitForSession = XCTestExpectation(description: "Wait for getSessionDetails to finish")

        do {
            let crossDeviceSessionFetcher = try CrossDeviceSessionFetcher(
                pushNotificationPayload: payload,
                miraclAPI: api,
                logger: logger
            ) { result in
                completionHandler(result)
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
        sessionId: String
    ) {
        do {
            let fetchedDetails = try XCTUnwrap(crossDeviceSession)

            XCTAssertEqual(fetchedDetails.userId, randomString)
            XCTAssertEqual(fetchedDetails.projectId, randomString)
            XCTAssertEqual(fetchedDetails.sessionId, sessionId)
            XCTAssertEqual(fetchedDetails.sessionDescription, randomString)
            XCTAssertEqual(fetchedDetails.signingHash, randomString)

        } catch {
            XCTFail("Get session detail failed")
        }
    }
}
