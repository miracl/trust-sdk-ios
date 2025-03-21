import MIRACLTrust
import XCTest

class SigningSessionDetailsTest: XCTestCase {
    let projectId = ProcessInfo.processInfo.environment["projectIdDV"]!

    let platformURL = ProcessInfo.processInfo.environment["platformURL"]!
    let userId = "int@miracl.com"
    let testTransaction = "Test transaction"
    var api = PlatformAPIWrapper()
    var qrCode: String?

    override func setUpWithError() throws {
        try super.setUpWithError()

        let platformURL = try XCTUnwrap(URL(string: platformURL))

        let configuration = try Configuration
            .Builder(projectId: projectId)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        qrCode = try XCTUnwrap(
            api.startSigningSession(
                projectID: projectId,
                userID: userId,
                hash: UUID().uuidString,
                description: testTransaction
            )
        )
    }

    func testSigningSessionDetails() throws {
        try getSigningSessionDetailsTest(
            qrCode: XCTUnwrap(qrCode)
        ) { sessionDetails, error in
            XCTAssertNotNil(sessionDetails)
            XCTAssertNil(error)
        }
    }

    func testSigningSessionDetailsFromUniversalLinkURL() throws {
        let qrCodeURL = try XCTUnwrap(URL(string: XCTUnwrap(qrCode)))

        getSigningSessionDetailsTest(
            qrURL: qrCodeURL
        ) { sessionDetails, error in
            XCTAssertNotNil(sessionDetails)
            XCTAssertNil(error)
        }
    }

    func testSigningSessionDetailsInvalidQRCode() throws {
        var invalidQRCode = try XCTUnwrap(URLComponents(string: XCTUnwrap(qrCode)))
        invalidQRCode.fragment = ""

        let qrCode = try XCTUnwrap(invalidQRCode.url?.absoluteString)

        getSigningSessionDetailsTest(
            qrCode: qrCode
        ) { sessionDetails, error in
            XCTAssertNil(sessionDetails)
            XCTAssertNotNil(error)
            assertError(
                current: error,
                expected: SigningSessionError.invalidQRCode
            )
        }
    }

    func testSigningSessionDetailsInvalidUniversalLinkURL() throws {
        var invalidQRCode = try XCTUnwrap(URLComponents(string: XCTUnwrap(qrCode)))
        invalidQRCode.fragment = ""

        let qrCode = try XCTUnwrap(invalidQRCode.url)

        getSigningSessionDetailsTest(
            qrURL: qrCode
        ) { sessionDetails, error in
            XCTAssertNil(sessionDetails)
            XCTAssertNotNil(error)
            assertError(
                current: error,
                expected: SigningSessionError.invalidUniversalLinkURL
            )
        }
    }

    func testInvalidSesssion() throws {
        var invalidQRCode = try XCTUnwrap(URLComponents(string: XCTUnwrap(qrCode)))
        invalidQRCode.fragment = "invalidSessionId"

        let qrCode = try XCTUnwrap(invalidQRCode.url)

        getSigningSessionDetailsTest(
            qrURL: qrCode
        ) { sessionDetails, error in
            XCTAssertNil(sessionDetails)
            XCTAssertNotNil(error)
            assertError(
                current: error,
                expected: SigningSessionError.invalidSigningSession
            )
        }
    }

    // MARK: Private

    private func getSigningSessionDetailsTest(
        qrCode: String,
        sessionCompletionHandler: @escaping SigningSessionDetailsCompletionHandler
    ) {
        let getSigningSessionDetailsExpectation = XCTestExpectation(
            description: "Get Signing Session Details from qrCode"
        )
        MIRACLTrust.getInstance().getSigningSessionDetailsFromQRCode(
            qrCode: qrCode,
            completionHandler: { sessionDetails, error in
                sessionCompletionHandler(sessionDetails, error)
                getSigningSessionDetailsExpectation.fulfill()
            }
        )
        wait(for: [getSigningSessionDetailsExpectation], timeout: operationTimeout)
    }

    private func getSigningSessionDetailsTest(
        qrURL: URL,
        sessionCompletionHandler: @escaping SigningSessionDetailsCompletionHandler
    ) {
        let getSigningSessionDetailsExpectation = XCTestExpectation(
            description: "Get Signing Session Details from qrURL"
        )
        MIRACLTrust.getInstance().getSigningSessionDetailsFromUniversalLinkURL(
            universalLinkURL: qrURL,
            completionHandler: { sessionDetails, error in
                sessionCompletionHandler(sessionDetails, error)
                getSigningSessionDetailsExpectation.fulfill()
            }
        )
        wait(for: [getSigningSessionDetailsExpectation], timeout: operationTimeout)
    }
}
