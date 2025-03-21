@testable import MIRACLTrust
import XCTest

class SigningSessionDetailsFetcherTest: XCTestCase {
    var sessionId = "41406ad19210511cecaf352aa187ea49"
    var qrCode = ""
    var universalLinkURL: URL?
    var api = MockAPI()

    let randomUUID = UUID().uuidString
    let currentDate = Int64(Date().timeIntervalSince1970)
    let pinLength = 4
    var signingSessionStatus = "active"
    var randomBool = Bool.random()

    override func setUpWithError() throws {
        api = MockAPI()

        qrCode = "https://mobile.int.miracl.net/dvs#\(sessionId)"
        universalLinkURL = URL(string: qrCode)

        api.signingSessionDetailsResponse = createSigningSessionDetails()
        api.signingSessionDetailsError = nil
        api.signingSessionDetailsResultCall = .success

        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString
            )
            .build()
        try MIRACLTrust.configure(with: configuration)
    }

    func testSigningSessionDetailsFetcher() throws {
        let randomUUIDCopy = randomUUID
        let randomBoolCopy = randomBool
        let pinLengthCopy = pinLength
        let currentDateCopy = currentDate

        try signingSessionDetailsFetcherQRCode { signingSessionDetails, error in
            XCTAssertNil(error)
            XCTAssertNotNil(signingSessionDetails)

            do {
                let unwrappedSessionDetails = try XCTUnwrap(signingSessionDetails)
                XCTAssertEqual(unwrappedSessionDetails.userId, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.signingHash, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.signingDescription, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.status, SigningSessionStatus.active)
                XCTAssertEqual(unwrappedSessionDetails.projectId, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.projectName, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.projectLogoURL, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.verificationMethod, VerificationMethod.standardEmail)
                XCTAssertEqual(unwrappedSessionDetails.verificationURL, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.verificationCustomText, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.identityType, IdentityType.email)
                XCTAssertEqual(unwrappedSessionDetails.identityTypeLabel, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.pinLength, pinLengthCopy)
                XCTAssertEqual(unwrappedSessionDetails.quickCodeEnabled, randomBoolCopy)
                XCTAssertEqual(unwrappedSessionDetails.limitQuickCodeRegistration, randomBoolCopy)
                XCTAssertEqual(unwrappedSessionDetails.expireTime, Date(timeIntervalSince1970: TimeInterval(currentDateCopy)))
            } catch {
                XCTFail("No signingSessionDetails object")
            }
        }
    }

    func testSigningSessionDetailsFetcherURL() throws {
        let randomUUIDCopy = randomUUID
        let randomBoolCopy = randomBool
        let pinLengthCopy = pinLength
        let currentDateCopy = currentDate

        try signingSessionDetailsFetcherUniversalLinkURL { signingSessionDetails, error in
            XCTAssertNil(error)
            XCTAssertNotNil(signingSessionDetails)

            do {
                let unwrappedSessionDetails = try XCTUnwrap(signingSessionDetails)
                XCTAssertEqual(unwrappedSessionDetails.userId, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.signingHash, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.signingDescription, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.status, SigningSessionStatus.active)
                XCTAssertEqual(unwrappedSessionDetails.projectId, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.projectName, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.projectLogoURL, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.verificationMethod, VerificationMethod.standardEmail)
                XCTAssertEqual(unwrappedSessionDetails.verificationURL, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.verificationCustomText, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.identityType, IdentityType.email)
                XCTAssertEqual(unwrappedSessionDetails.identityTypeLabel, randomUUIDCopy)
                XCTAssertEqual(unwrappedSessionDetails.pinLength, pinLengthCopy)
                XCTAssertEqual(unwrappedSessionDetails.quickCodeEnabled, randomBoolCopy)
                XCTAssertEqual(unwrappedSessionDetails.limitQuickCodeRegistration, randomBoolCopy)
                XCTAssertEqual(unwrappedSessionDetails.expireTime, Date(timeIntervalSince1970: TimeInterval(currentDateCopy)))
            } catch {
                XCTFail("No signingSessionDetails object")
            }
        }
    }

    func testEmptyResponse() throws {
        api.signingSessionDetailsResponse = nil
        api.signingSessionDetailsError = nil
        api.signingSessionDetailsResultCall = .success

        try signingSessionDetailsFetcherQRCode { signingSessionDetails, error in
            assertError(current: error, expected: SigningSessionError.getSigningSessionDetailsFail(nil))
            XCTAssertNil(signingSessionDetails)
        }
    }

    func testBadStatusCode() throws {
        let cause = APIError.apiServerError(statusCode: 401, message: nil, requestURL: nil)
        let expectedError = SigningSessionError.getSigningSessionDetailsFail(cause)
        api.signingSessionDetailsResponse = nil
        api.signingSessionDetailsError = cause
        api.signingSessionDetailsResultCall = .failed

        try signingSessionDetailsFetcherQRCode { signingSessionDetails, error in
            assertError(current: error, expected: expectedError)
            XCTAssertNil(signingSessionDetails)
        }
    }

    func testEmptySessionID() throws {
        sessionId = ""
        qrCode = "https://mobile.int.miracl.net/dvs#\(sessionId)"

        let expectedError = SigningSessionError.invalidQRCode

        try XCTAssertThrowsError(
            SigningSessionDetailsFetcher(
                qrCode: qrCode,
                completionHandler: { _, _ in }
            )
        ) { error in
            assertError(current: error, expected: expectedError)
        }
    }

    func testEmptyNoFragmentSessionID() throws {
        qrCode = "https://mobile.int.miracl.net/dvs\(sessionId)"

        let expectedError = SigningSessionError.invalidQRCode

        try XCTAssertThrowsError(
            SigningSessionDetailsFetcher(
                qrCode: qrCode,
                completionHandler: { _, _ in }
            )
        ) { error in
            assertError(current: error, expected: expectedError)
        }
    }

    func testEmptyNoFragmentSessionIDUniversalLinkURL() throws {
        qrCode = "https://mobile.int.miracl.net/dvs"
        universalLinkURL = URL(string: qrCode)

        let expectedError = SigningSessionError.invalidUniversalLinkURL

        try XCTAssertThrowsError(
            SigningSessionDetailsFetcher(
                universalLinkURL: XCTUnwrap(universalLinkURL),
                completionHandler: { _, _ in }
            )
        ) { error in
            assertError(current: error, expected: expectedError)
        }
    }

    func testInvalidQRCodeURL() throws {
        qrCode = "Definitely not url!1!"

        let expectedError = SigningSessionError.invalidQRCode

        try XCTAssertThrowsError(
            SigningSessionDetailsFetcher(
                qrCode: qrCode,
                completionHandler: { _, _ in }
            )
        ) { error in
            assertError(current: error, expected: expectedError)
        }
    }

    func testInvalidSigningSession() throws {
        let expectedError = SigningSessionError.invalidSigningSession

        api.signingSessionDetailsResponse = nil
        api.signingSessionDetailsResultCall = .failed
        api.signingSessionDetailsError = apiClientError(
            with: INVALID_REQUEST_PARAMETERS,
            context: ["params": "id"]
        )

        try signingSessionDetailsFetcherQRCode { signingSessionDetails, error in
            assertError(current: error, expected: expectedError)
            XCTAssertNil(signingSessionDetails)
        }
    }

    private func signingSessionDetailsFetcherQRCode(
        completionHandler: @escaping SigningSessionDetailsCompletionHandler
    ) throws {
        do {
            let expectation = XCTestExpectation(description: "Wait for signing session fetch")

            let fetcher = try SigningSessionDetailsFetcher(
                qrCode: qrCode,
                miraclAPI: api,
                completionHandler: { signingSessionDetails, error in
                    completionHandler(signingSessionDetails, error)
                    expectation.fulfill()
                }
            )

            fetcher.fetch()
            let waitResult = XCTWaiter.wait(for: [expectation], timeout: 10.0)
            if waitResult != .completed {
                XCTFail("Failed expectation")
            }
        } catch {
            XCTFail("Cannot fetch signing session details")
        }
    }

    private func signingSessionDetailsFetcherUniversalLinkURL(
        completionHandler: @escaping SigningSessionDetailsCompletionHandler
    ) throws {
        do {
            let expectation = XCTestExpectation(description: "Wait for signing session fetch for URL")

            let fetcher = try SigningSessionDetailsFetcher(
                universalLinkURL: XCTUnwrap(universalLinkURL),
                miraclAPI: api,
                completionHandler: { signingSessionDetails, error in
                    completionHandler(signingSessionDetails, error)
                    expectation.fulfill()
                }
            )

            fetcher.fetch()
            let waitResult = XCTWaiter.wait(for: [expectation], timeout: 10.0)
            if waitResult != .completed {
                XCTFail("Failed expectation")
            }
        } catch {
            XCTFail("Cannot fetch signing session details")
        }
    }

    private func apiClientError(with code: String, context: [String: String]? = nil) -> APIError {
        let clientErrorData = ClientErrorData(
            code: code,
            info: "",
            context: context
        )

        return APIError.apiClientError(
            clientErrorData: clientErrorData,
            requestId: "",
            message: nil,
            requestURL: nil
        )
    }

    private func createSigningSessionDetails() -> SigningSessionDetailsResponse {
        SigningSessionDetailsResponse(
            userID: randomUUID,
            signingHash: randomUUID,
            signingDescription: randomUUID,
            status: signingSessionStatus,
            expireTime: currentDate,
            projectId: randomUUID,
            projectName: randomUUID,
            projectLogoURL: randomUUID,
            verificationMethod: "standardEmail",
            verificationURL: randomUUID,
            verificationCustomText: randomUUID,
            identityType: "email",
            identityTypeLabel: randomUUID,
            pinLength: pinLength,
            enableRegistrationCode: randomBool,
            limitRegCodeVerified: randomBool
        )
    }
}
