@testable import MIRACLTrust
import XCTest

class AbortSessionIntegrationTests: XCTestCase {
    var userId = ""
    var accessId = ""

    var sessionDetails: AuthenticationSessionDetails?

    let platformURL = ProcessInfo.processInfo.environment["platformURL"]!
    let projectId = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let clientId = ProcessInfo.processInfo.environment["clientIdCUV"]!
    let clientSecret = ProcessInfo.processInfo.environment["clientSecretCUV"]!

    var abortSessionTestCase = AbortSessionTestCase()
    var registrationTestCase = RegistrationTestCase()
    var sessionDetailsTestCase = SessionDetailsTestCase()
    var getActivationToken = GetActivationTokenTestCase()

    var activationToken = ""
    let api = PlatformAPIWrapper()

    var storage = SQLiteUserStorage(
        projectId: ProcessInfo.processInfo.environment["projectIdCUV"]!,
        databaseName: testDBName
    )

    override func setUpWithError() throws {
        userId = "global@example.com"

        registrationTestCase = RegistrationTestCase()
        registrationTestCase.pinCode = "8902"

        let platformURL = try XCTUnwrap(URL(string: platformURL))

        let configuration = try Configuration
            .Builder(projectId: projectId)
            .platformURL(url: platformURL)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        accessId = try XCTUnwrap(api.getAccessId(projectId: projectId))

        let (response, _) = getActivationToken.getActivationToken(
            clientId: clientId,
            clientSecret: clientSecret,
            projectId: projectId,
            userId: userId,
            accessId: accessId
        )

        activationToken = try XCTUnwrap(response?.activationToken)

        _ = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        let (details, _) = sessionDetailsTestCase.getSessionDetails(qrCode: "https://mcl.mpin.io#\(accessId)")

        sessionDetails = try XCTUnwrap(details)
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

    func testAbortSession() throws {
        let (sessionAborted, error) = try abortSessionTestCase.abortSession(
            sessionDetails: XCTUnwrap(sessionDetails)
        )

        XCTAssertTrue(sessionAborted)
        XCTAssertNil(error)
    }

    func testAbortSessionEmptyAccessId() throws {
        let sessionDetails = createAuthenticationSessionDetails(accessId: "")

        let (sessionAborted, error) = abortSessionTestCase.abortSession(
            sessionDetails: sessionDetails
        )

        XCTAssertFalse(sessionAborted)
        assertError(current: error, expected: AuthenticationSessionError.invalidAuthenticationSessionDetails)
    }

    private func createAuthenticationSessionDetails(
        accessId: String = UUID().uuidString
    ) -> AuthenticationSessionDetails {
        AuthenticationSessionDetails(
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
            accessId: accessId
        )
    }
}
