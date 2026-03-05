@testable import MIRACLTrust
import XCTest

class AbortSessionIntegrationTests: XCTestCase {
    var userId = ""

    var sessionDetails: AuthenticationSessionDetails?

    let platformURLCUV = ProcessInfo.processInfo.environment["projectURLCUV"]!
    let projectId = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let serviceAccountToken = ProcessInfo.processInfo.environment["serviceAccountTokenCUV"]!

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

    override func setUp() async throws {
        userId = "global@example.com"

        registrationTestCase = RegistrationTestCase()
        registrationTestCase.pinCode = "8902"

        let configuration = try Configuration
            .Builder(projectId: projectId, projectURL: platformURLCUV)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let session = try XCTUnwrap(api.startSession(projectId: projectId, projectURL: platformURLCUV))

        let (response, _) = await getActivationToken.getActivationToken(
            serviceAccountToken: serviceAccountToken,
            projectId: projectId,
            projectURL: platformURLCUV,
            userId: userId,
            accessId: session.accessId
        )

        activationToken = try XCTUnwrap(response?.activationToken)

        _ = await registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        let (details, _) = await sessionDetailsTestCase.getSessionDetails(qrCode: "https://mcl.mpin.io#\(session.accessId)")

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

    func testAbortSession() async throws {
        let (sessionAborted, error) = try await abortSessionTestCase.abortSession(
            sessionDetails: XCTUnwrap(sessionDetails)
        )

        XCTAssertTrue(sessionAborted)
        XCTAssertNil(error)
    }

    func testAbortSessionEmptyAccessId() async {
        let sessionDetails = createAuthenticationSessionDetails(accessId: "")

        let (sessionAborted, error) = await abortSessionTestCase.abortSession(
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
            identityType: .alphanumeric,
            accessId: accessId
        )
    }
}
