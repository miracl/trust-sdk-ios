@testable import MIRACLTrust
import XCTest

class QuickCodeIntegrationTests: XCTestCase {
    var registrationTestCase = RegistrationTestCase()
    var authenticationTestCase = QRAuthenticationTestCase()
    var quickCodeTestCase = QuickCodeTestCase()
    var getActivationToken = GetActivationTokenTestCase()
    var session: StartSessionResult?
    var activationToken = ""
    var configuration: Configuration?

    var storage = SQLiteUserStorage(
        projectId: ProcessInfo.processInfo.environment["projectIdCUV"]!,
        databaseName: testDBName
    )

    let projectURL = ProcessInfo.processInfo.environment["projectURLCUV"]!
    let projectId = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let serviceAccountToken = ProcessInfo.processInfo.environment["serviceAccountTokenCUV"]!

    let userId = "global@example.com"
    let randomPIN = String(Int32.random(in: 1000 ..< 9999))
    let api = PlatformAPIWrapper()

    override func setUp() async throws {
        try await super.setUp()

        registrationTestCase = RegistrationTestCase()
        registrationTestCase.pinCode = randomPIN

        quickCodeTestCase = QuickCodeTestCase()
        quickCodeTestCase.authenticationPinCode = randomPIN

        session = api.startSession(projectId: projectId, projectURL: projectURL)
        let session = try XCTUnwrap(session)

        configuration = try Configuration
            .Builder(projectId: projectId, projectURL: projectURL)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        authenticationTestCase.pinCode = randomPIN

        let (response, _) = await getActivationToken.getActivationToken(
            serviceAccountToken: serviceAccountToken,
            projectId: projectId,
            projectURL: projectURL,
            userId: userId,
            accessId: session.accessId
        )

        activationToken = try XCTUnwrap(response?.activationToken)
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

    func testSuccessfulQuickCodeGeneration() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        let (quickCode, quickCodeError) = try await quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCodeError)
        XCTAssertNotNil(quickCode)
    }

    func testFailedQuickCodeGenerationEmptyIdentity() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let emptyUser = createRandomUser(
            mpinId: Data(),
            token: Data(),
            dtas: ""
        )

        let (quickCode, quickCodeError) = await quickCodeTestCase.generateQuickCode(user: emptyUser)

        XCTAssertNil(quickCode)
        assertError(current: quickCodeError, expected: QuickCodeError.generationFail(AuthenticationError.invalidUserData))
    }

    func testFailedQuickCodeGenerationDifferentPIN() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))
        let (user, regError) = await registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        var differentPin = String(Int32.random(in: 1000 ..< 9999))
        if differentPin == quickCodeTestCase.authenticationPinCode {
            while quickCodeTestCase.authenticationPinCode == differentPin {
                differentPin = String(Int32.random(in: 1000 ..< 9999))
            }
        }

        quickCodeTestCase.authenticationPinCode = differentPin

        let (quickCode, quickCodeError) = try await quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))

        XCTAssertNil(quickCode)
        assertError(
            current: quickCodeError,
            expected: QuickCodeError.unsuccessfulAuthentication
        )
    }

    func testFailedQuickCodeShorterPINGeneration() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        quickCodeTestCase.authenticationPinCode = String(Int32.random(in: 100 ..< 999))
        let (quickCode, quickCodeError) = try await quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCode)

        assertError(
            current: quickCodeError,
            expected: QuickCodeError.invalidPin
        )
    }

    func testFailedQuickCodeLongerPINGeneration() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        quickCodeTestCase.authenticationPinCode = String(Int32.random(in: 100_000 ..< 999_999))
        let (quickCode, quickCodeError) = try await quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCode)

        assertError(
            current: quickCodeError,
            expected: QuickCodeError.invalidPin
        )
    }

    func testFailedQuickCodeNilPINGeneration() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        quickCodeTestCase.authenticationPinCode = nil
        let (quickCode, quickCodeError) = try await quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCode)
        assertError(
            current: quickCodeError,
            expected: QuickCodeError.pinCancelled
        )
    }

    func testUnsuccessfulAuthenticationQuickCodeGeneration() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        var differentPin = String(Int32.random(in: 1000 ..< 9999))
        if differentPin == quickCodeTestCase.authenticationPinCode {
            while quickCodeTestCase.authenticationPinCode == differentPin {
                differentPin = String(Int32.random(in: 1000 ..< 9999))
            }
        }
        quickCodeTestCase.authenticationPinCode = differentPin

        // First try
        var (quickCode, quickCodeError) = try await quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCode)
        assertError(
            current: quickCodeError,
            expected: QuickCodeError.unsuccessfulAuthentication
        )

        // Second try
        (quickCode, quickCodeError) = try await quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCode)
        assertError(
            current: quickCodeError,
            expected: QuickCodeError.unsuccessfulAuthentication
        )

        // Third try. QuickCode generation should return an error that indicates for revoked identity.
        (quickCode, quickCodeError) = try await quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCode)
        assertError(
            current: quickCodeError,
            expected: QuickCodeError.revoked
        )

        // After three unsuccessful tries, the user is blocked and cannot authenticate anymore.
        let session = try XCTUnwrap(session)
        let qrCode = "https://mcl.mpin.io/mobile-login/#\(session.accessId)"
        let (authenticationResult, authenticationError) = try await authenticationTestCase.authenticateUser(
            user: XCTUnwrap(user),
            qrCode: qrCode
        )

        XCTAssertFalse(authenticationResult)
        assertError(current: authenticationError, expected: AuthenticationError.revoked)
    }

    func createRandomUser(
        mpinId: Data = Data([1, 2, 3]),
        token: Data = Data([4, 5, 6]),
        dtas: String = UUID().uuidString
    ) -> User {
        User(
            userId: "example@example.com",
            projectId: UUID().uuidString,
            revoked: false,
            pinLength: 4,
            mpinId: mpinId,
            token: token,
            dtas: dtas,
            publicKey: nil
        )
    }
}
