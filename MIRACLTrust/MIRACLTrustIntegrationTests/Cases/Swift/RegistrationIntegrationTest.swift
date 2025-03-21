@testable import MIRACLTrust
import XCTest

class RegistrationIntegrationTests: XCTestCase {
    let gmailService = GmailServiceTestWrapper()

    let platformURL = ProcessInfo.processInfo.environment["platformURL"]!

    let projectIdDV = ProcessInfo.processInfo.environment["projectIdDV"]!

    let clientIdPV = ProcessInfo.processInfo.environment["clientIdCUV"]!
    let projectIdPV = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let clientSecretPV = ProcessInfo.processInfo.environment["clientSecretCUV"]!

    let verificationTestCase = VerificationTestCase()
    let getActivationTokenTestCase = GetActivationTokenTestCase()
    let registrationTestCase = RegistrationTestCase()
    let quickCodeTestCase = QuickCodeTestCase()
    let authenticationTestCase = JWTAuthenticationTestCase()
    let userId = "int@miracl.com"
    let api = PlatformAPIWrapper()

    var randomPin = String(Int32.random(in: 1000 ..< 9999))
    var anotherRandomPin = String(Int32.random(in: 1000 ..< 9999))
    var storage = SQLiteUserStorage(
        projectId: ProcessInfo.processInfo.environment["projectIdCUV"]!,
        databaseName: testDBName
    )

    var configuration: Configuration?
    var activationToken = ""

    override func setUpWithError() throws {
        try super.setUpWithError()

        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectIdPV)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        registrationTestCase.pinCode = randomPin
        quickCodeTestCase.authenticationPinCode = randomPin
        authenticationTestCase.pinCode = anotherRandomPin

        let (response, _) = getActivationTokenTestCase.getActivationToken(
            clientId: clientIdPV,
            clientSecret: clientSecretPV,
            projectId: projectIdPV,
            userId: userId
        )

        activationToken = try XCTUnwrap(response?.activationToken)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        let path = DBFileHelper.getDBFilePath()
        if !path.isEmpty {
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(atPath: path)
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: path))
        }
    }

    func testSuccessfulRegistrationDefaultVerification() async throws {
        let currentUserId = "int+\(UUID().uuidString)@miracl.com"

        try MIRACLTrust
            .getInstance()
            .setProjectId(projectId: projectIdDV)

        let timestamp = Date()
        let (verified, error) = verificationTestCase.sendVerificationEmail(userId: currentUserId)
        XCTAssertNotNil(verified)
        XCTAssertNil(error)

        let verificationURL = try await gmailService.getVerificationURL(receiver: currentUserId, timestamp: timestamp)
        let unwrappedVerificationURL = try XCTUnwrap(verificationURL)

        let (token, tokenError) = getActivationTokenTestCase.getActivationToken(verificationURL: unwrappedVerificationURL)

        XCTAssertNil(tokenError)
        XCTAssertNotNil(token)

        let activationToken = try XCTUnwrap(token)
        let (user, regError) = registrationTestCase.registerUser(
            userId: currentUserId,
            activationToken: activationToken.activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)
    }

    func testSuccessfulRegistrationCustomVerification() throws {
        let verificationURLString = api.getVerificaitonURL(
            clientId: clientIdPV,
            clientSecret: clientSecretPV,
            projectId: projectIdPV,
            userId: userId
        )

        let verificationURL = try XCTUnwrap(verificationURLString)
        let (token, tokenError) = getActivationTokenTestCase.getActivationToken(verificationURL: verificationURL)

        XCTAssertNil(tokenError)
        XCTAssertNotNil(token)

        let activationToken = try XCTUnwrap(token)
        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken.activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)
    }

    func testSuccessfulRegistrationPluggableVerification() throws {
        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)
    }

    func testSuccessfulRegistrationQuickCode() throws {
        var (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        let (quickCode, quickCodeError) = try quickCodeTestCase.generateQuickCode(user: XCTUnwrap(user))

        XCTAssertNil(quickCodeError)
        XCTAssertNotNil(quickCode)

        let (activationTokenResponse, activationTokenError) = try getActivationTokenTestCase.getActivationToken(
            userId: XCTUnwrap(user?.userId),
            code: XCTUnwrap(quickCode?.code)
        )

        XCTAssertNil(activationTokenError)
        XCTAssertNotNil(activationTokenResponse)

        (user, regError) = try registrationTestCase.registerUser(
            userId: userId,
            activationToken: XCTUnwrap(activationTokenResponse?.activationToken)
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)
    }

    func testEmptyUserIdRegistration() {
        let emptyUserId = ""

        let (user, regError) = registrationTestCase.registerUser(
            userId: emptyUserId,
            activationToken: activationToken
        )

        XCTAssertNil(user)
        assertError(current: regError, expected: RegistrationError.emptyUserId)
    }

    func testEmptyActivationTokenFailedRegistration() throws {
        let emptyActivationToken = ""

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: emptyActivationToken
        )

        XCTAssertNil(user)
        assertError(current: regError, expected: RegistrationError.emptyActivationToken)
    }

    func testIncorrectActivationTokenFailedRegistration() throws {
        let emptyActivationToken = UUID().uuidString

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: emptyActivationToken
        )

        XCTAssertNil(user)
        assertError(current: regError, expected: RegistrationError.invalidActivationToken)
    }

    func testFailedRegistrationForCancelledPIN() {
        registrationTestCase.pinCode = nil

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(user)
        assertError(
            current: regError,
            expected: RegistrationError.pinCancelled
        )
    }

    func testFailedRegistrationForInvalidPIN() {
        registrationTestCase.pinCode = "InvalidPin"
        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(user)
        assertError(
            current: regError,
            expected: RegistrationError.invalidPin
        )
    }

    func testFailedRegistrationForEmptyPIN() {
        registrationTestCase.pinCode = ""

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(user)
        assertError(
            current: regError,
            expected: RegistrationError.invalidPin
        )
    }

    func testFailedRegistrationForLongerPIN() {
        let randomNum = Int32.random(in: 100_000_000 ..< 999_999_999)
        registrationTestCase.pinCode = String(randomNum)

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(user)
        assertError(
            current: regError,
            expected: RegistrationError.invalidPin
        )
    }

    func testFailedRegistrationForShorterPIN() {
        let randomNum = Int32.random(in: 1 ..< 999)
        registrationTestCase.pinCode = String(randomNum)

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(user)
        assertError(
            current: regError,
            expected: RegistrationError.invalidPin
        )
    }

    func testRegistrationOverride() throws {
        var (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        let registeredUser = try XCTUnwrap(user)
        let mpinId = registeredUser.mpinId

        let (response, _) = getActivationTokenTestCase.getActivationToken(
            clientId: clientIdPV,
            clientSecret: clientSecretPV,
            projectId: projectIdPV,
            userId: userId
        )

        activationToken = try XCTUnwrap(response?.activationToken)

        registrationTestCase.pinCode = String(Int32.random(in: 1000 ..< 9999))
        (user, regError) = registrationTestCase.registerUser(
            userId: userId, activationToken: activationToken
        )

        XCTAssertNil(regError)
        XCTAssertNotNil(user)
        XCTAssertNotEqual(mpinId, user?.mpinId)
    }

    func testRegistrationOverrideForRevokedUser() throws {
        var (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        var existingUser = try XCTUnwrap(user)

        var (jwt, error) = authenticationTestCase.generateJWT(user: existingUser)
        XCTAssertNotNil(error)
        XCTAssertNil(jwt)

        (jwt, error) = authenticationTestCase.generateJWT(user: existingUser)
        XCTAssertNotNil(error)
        XCTAssertNil(jwt)

        (jwt, error) = authenticationTestCase.generateJWT(user: existingUser)
        assertError(current: error, expected: AuthenticationError.revoked)
        XCTAssertNil(jwt)

        existingUser = try XCTUnwrap(MIRACLTrust.getInstance().getUser(by: userId))
        XCTAssertEqual(existingUser.revoked, true)

        let verificationURLString = api.getVerificaitonURL(
            clientId: clientIdPV,
            clientSecret: clientSecretPV,
            projectId: projectIdPV,
            userId: userId
        )
        let verificationURL = try XCTUnwrap(verificationURLString)

        let (token, tokenError) = getActivationTokenTestCase.getActivationToken(verificationURL: verificationURL)

        XCTAssertNil(tokenError)
        XCTAssertNotNil(token)

        (user, regError) = try registrationTestCase.registerUser(
            userId: userId,
            activationToken: XCTUnwrap(token?.activationToken)
        )

        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        existingUser = try XCTUnwrap(user)
        XCTAssertEqual(existingUser.revoked, false)
    }

    func testProjectMismatch() throws {
        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectIdDV)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()

        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (response, _) = getActivationTokenTestCase.getActivationToken(
            clientId: clientIdPV,
            clientSecret: clientSecretPV,
            projectId: projectIdPV,
            userId: userId
        )

        activationToken = try XCTUnwrap(response?.activationToken)

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(user)
        assertError(current: regError, expected: RegistrationError.projectMismatch)
    }
}
