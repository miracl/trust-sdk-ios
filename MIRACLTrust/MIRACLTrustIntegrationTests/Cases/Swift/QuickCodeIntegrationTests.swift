@testable import MIRACLTrust
import XCTest

class QuickCodeIntegrationTests: XCTestCase {
    var registrationTestCase = RegistrationTestCase()
    var authenticationTestCase = QRAuthenticationTestCase()
    var quickCodeTestCase = QuickCodeTestCase()
    var getActivationToken = GetActivationTokenTestCase()
    var accessId = ""
    var activationToken = ""
    var configuration: Configuration?

    var storage = SQLiteUserStorage(
        projectId: ProcessInfo.processInfo.environment["projectIdCUV"]!,
        databaseName: testDBName
    )

    let platformURL = ProcessInfo.processInfo.environment["platformURL"]!
    let projectId = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let clientId = ProcessInfo.processInfo.environment["clientIdCUV"]!
    let clientSecret = ProcessInfo.processInfo.environment["clientSecretCUV"]!

    let userId = "global@example.com"
    let randomPIN = String(Int32.random(in: 1000 ..< 9999))
    let api = PlatformAPIWrapper()

    override func setUpWithError() throws {
        try super.setUpWithError()

        registrationTestCase = RegistrationTestCase()
        registrationTestCase.pinCode = randomPIN

        quickCodeTestCase = QuickCodeTestCase()
        quickCodeTestCase.authenticationPinCode = randomPIN

        accessId = try XCTUnwrap(api.getAccessId(projectId: projectId))

        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectId)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        authenticationTestCase.pinCode = randomPIN

        let (response, _) = getActivationToken.getActivationToken(
            clientId: clientId,
            clientSecret: clientSecret,
            projectId: projectId,
            userId: userId,
            accessId: accessId
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

    func testSuccessfulQuickCodeGeneration() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        let (quickCode, quickCodeError) = try quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCodeError)
        XCTAssertNotNil(quickCode)
    }

    func testFailedQuickCodeGenerationEmptyIdentity() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let emptyUser = createRandomUser(
            mpinId: Data(),
            token: Data(),
            dtas: ""
        )

        let (quickCode, quickCodeError) = quickCodeTestCase.generateQuickCode(user: emptyUser)

        XCTAssertNil(quickCode)
        assertError(current: quickCodeError, expected: QuickCodeError.generationFail(AuthenticationError.invalidUserData))
    }

    func testFailedQuickCodeGenerationDifferentPIN() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))
        let (user, regError) = registrationTestCase.registerUser(
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

        let (quickCode, quickCodeError) = try quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))

        XCTAssertNil(quickCode)
        assertError(
            current: quickCodeError,
            expected: QuickCodeError.unsuccessfulAuthentication
        )
    }

    func testFailedQuickCodeShorterPINGeneration() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        quickCodeTestCase.authenticationPinCode = String(Int32.random(in: 100 ..< 999))
        let (quickCode, quickCodeError) = try quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCode)

        assertError(
            current: quickCodeError,
            expected: QuickCodeError.invalidPin
        )
    }

    func testFailedQuickCodeLongerPINGeneration() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        quickCodeTestCase.authenticationPinCode = String(Int32.random(in: 100_000 ..< 999_999))
        let (quickCode, quickCodeError) = try quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCode)

        assertError(
            current: quickCodeError,
            expected: QuickCodeError.invalidPin
        )
    }

    func testFailedQuickCodeNilPINGeneration() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        quickCodeTestCase.authenticationPinCode = nil
        let (quickCode, quickCodeError) = try quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCode)
        assertError(
            current: quickCodeError,
            expected: QuickCodeError.pinCancelled
        )
    }

    func testUnsuccessfulAuthenticationQuickCodeGeneration() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registrationTestCase.registerUser(
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
        var (quickCode, quickCodeError) = try quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCode)
        assertError(
            current: quickCodeError,
            expected: QuickCodeError.unsuccessfulAuthentication
        )

        // Second try
        (quickCode, quickCodeError) = try quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCode)
        assertError(
            current: quickCodeError,
            expected: QuickCodeError.unsuccessfulAuthentication
        )

        // Third try. QuickCode generation should return an error that indicates for revoked identity.
        (quickCode, quickCodeError) = try quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCode)
        assertError(
            current: quickCodeError,
            expected: QuickCodeError.revoked
        )

        // After three unsuccessful tries, the user is blocked and cannot authenticate anymore.
        let qrCode = "https://mcl.mpin.io/mobile-login/#\(accessId)"
        let (authenticationResult, authenticationError) = try authenticationTestCase.authenticateUser(
            user: XCTUnwrap(user),
            qrCode: qrCode
        )

        XCTAssertFalse(authenticationResult)
        assertError(current: authenticationError, expected: AuthenticationError.revoked)
    }

    func testLimitedQuickCodeGeneration() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        // Register user with QuickCode
        var (quickCode, quickCodeError) = try quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))
        XCTAssertNil(quickCodeError)
        XCTAssertNotNil(quickCode)

        let (newActicationTokenResponse, _) = try getActivationToken.getActivationToken(userId: userId, code: XCTUnwrap(quickCode?.code))

        let (quickCodeGeneratedUser, quickCodeUserRegError) = try registrationTestCase.registerUser(
            userId: userId,
            activationToken: XCTUnwrap(newActicationTokenResponse?.activationToken)
        )
        XCTAssertNil(quickCodeUserRegError)
        XCTAssertNotNil(quickCodeGeneratedUser)

        // Try to generate QuickCode with user registered with QuickCode and Limit QuickCode Verified
        // option enabled for the project.
        (quickCode, quickCodeError) = try quickCodeTestCase.generateQuickCode(user: XCTUnwrap(quickCodeGeneratedUser))
        XCTExpectFailure("QuickCodeError.limitedQuickCodeGeneration is currently disabled and quick code is generated")
        XCTAssertNil(quickCode)
        assertError(
            current: quickCodeError,
            expected: QuickCodeError.limitedQuickCodeGeneration
        )
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
