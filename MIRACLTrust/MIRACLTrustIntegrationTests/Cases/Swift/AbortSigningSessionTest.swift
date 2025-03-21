@testable import MIRACLTrust
import XCTest

final class AbortSigningSessionTest: XCTestCase {
    var signingSessionAborterTestCase = SigningSessionAborterTestCase()
    var signingSessionDetailsCase = GetSigningSessionDetailsTestCase()

    let platformURL = ProcessInfo.processInfo.environment["platformURL"]!
    let projectId = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let api = PlatformAPIWrapper()

    var storage = SQLiteUserStorage(
        projectId: ProcessInfo.processInfo.environment["projectIdCUV"]!,
        databaseName: testDBName
    )

    var qrCode = ""
    var signingSessionDetails: SigningSessionDetails?

    override func setUpWithError() throws {
        let platformURL = try XCTUnwrap(URL(string: platformURL))

        let configuration = try Configuration
            .Builder(projectId: projectId)
            .platformURL(url: platformURL)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        qrCode = try XCTUnwrap(
            api.startSigningSession(
                projectID: projectId,
                userID: "global@example.com",
                hash: UUID().uuidString,
                description: "Test transaction"
            )
        )

        let (signingSessionDetailsFromMethod, _) = signingSessionDetailsCase.getSigningSessionDetails(qrCode: qrCode)
        signingSessionDetails = try XCTUnwrap(signingSessionDetailsFromMethod)
    }

    override func tearDown() {
        super.tearDown()

        do {
            let path = DBFileHelper.getDBFilePath()
            if !path.isEmpty {
                if FileManager.default.fileExists(atPath: path) {
                    try FileManager.default.removeItem(atPath: path)
                }
                XCTAssertFalse(FileManager.default.fileExists(atPath: path))
            }
        } catch {
            XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
        }
    }

    func testAbortSigningSession() throws {
        let (aborted, error) = try signingSessionAborterTestCase.abortSigningSession(
            signingSessionDetails: XCTUnwrap(signingSessionDetails)
        )

        XCTAssertTrue(aborted)
        XCTAssertNil(error)
    }

    func testAbortSigningSessionWithExpiredSessionId() throws {
        signingSessionDetails = createSigningSessionDetails(sessionId: "d68645df833eda82f1ebec68b8e67202")

        let expectedError = SigningSessionError.invalidSigningSession

        let (aborted, error) = try signingSessionAborterTestCase.abortSigningSession(
            signingSessionDetails: XCTUnwrap(signingSessionDetails)
        )

        XCTAssertFalse(aborted)
        assertError(current: error, expected: expectedError)
    }

    func testAbortSigningSessionWithEmptySessionId() throws {
        signingSessionDetails = createSigningSessionDetails(sessionId: "  ")

        let expectedError = SigningSessionError.invalidSigningSessionDetails

        let (aborted, error) = try signingSessionAborterTestCase.abortSigningSession(
            signingSessionDetails: XCTUnwrap(signingSessionDetails)
        )

        XCTAssertFalse(aborted)
        assertError(current: error, expected: expectedError)
    }

    private func createSigningSessionDetails(sessionId: String = UUID().uuidString) -> SigningSessionDetails {
        SigningSessionDetails(
            userId: UUID().uuidString,
            projectName: UUID().uuidString,
            projectLogoURL: UUID().uuidString,
            projectId: UUID().uuidString,
            pinLength: 4,
            verificationMethod: .fullCustom,
            verificationURL: UUID().uuidString,
            verificationCustomText: UUID().uuidString,
            identityTypeLabel: UUID().uuidString,
            quickCodeEnabled: Bool.random(),
            limitQuickCodeRegistration: Bool.random(),
            identityType: .alphanumeric,
            sessionId: sessionId,
            signingHash: UUID().uuidString,
            signingDescription: UUID().uuidString,
            status: .active,
            expireTime: Date()
        )
    }
}
