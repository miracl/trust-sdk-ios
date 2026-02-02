@testable import MIRACLTrust
import XCTest

class RegistrationIntegrationTests: XCTestCase {
    let gmailService = GmailServiceTestWrapper()

    let projectURL = ProcessInfo.processInfo.environment["projectURLCUV"]!

    let projectIdDV = ProcessInfo.processInfo.environment["projectIdDV"]!
    let projectURLDV = ProcessInfo.processInfo.environment["projectURLDV"]!

    let projectIdPV = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let serviceAccountToken = ProcessInfo.processInfo.environment["serviceAccountTokenCUV"]!

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

        configuration = try Configuration
            .Builder(projectId: projectIdPV, projectURL: projectURL)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        registrationTestCase.pinCode = randomPin
        quickCodeTestCase.authenticationPinCode = randomPin
        authenticationTestCase.pinCode = anotherRandomPin

        let (response, _) = getActivationTokenTestCase.getActivationToken(
            serviceAccountToken: serviceAccountToken,
            projectId: projectIdPV,
            projectURL: projectURL,
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
            .updateProjectSettings(projectId: projectIdDV, projectURL: projectURLDV)

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
            serviceAccountToken: serviceAccountToken,
            projectId: projectIdPV,
            projectURL: projectURL,
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

    func testSuccessfulRegistrationPluggableVerification() {
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

    func testEmptyActivationTokenFailedRegistration() {
        let emptyActivationToken = ""

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: emptyActivationToken
        )

        XCTAssertNil(user)
        assertError(current: regError, expected: RegistrationError.emptyActivationToken)
    }

    func testIncorrectActivationTokenFailedRegistration() {
        let incorrectActivationToken = "eyJhbGciOiJSUzI1NiIsImtpZCI6Ikg0OEJsaXRza0M5b2ZnaVdsY0Z3MzJ5QzhLZnF0X3RVWENaOGowTkxyT1k9IiwidHlwIjoiSldUIn0.eyJkZXZpY2VOYW1lIjoiaU9TIiwiZXhwIjoxNzYyMjUyMzQ0LCJpYXQiOjE3NjIyNTIyNTQsImlzcyI6Imh0dHBzOi8vYXBpLm1waW4uaW8iLCJqdGkiOiJmMDUwODNiOC0wMzM4LTQ2MDgtODAwZS0wOTAwZTdhOGFkM2YiLCJwcm9qZWN0SUQiOiJiMTg3ZThiYi0yN2FjLTQzMDAtYWQ2My1jMmUwMmU1YmJjZDMiLCJzY29wZSI6InZlcmlmaWNhdGlvbiIsInN1YiI6ImludEBtaXJhY2wuY29tIn0.5JEOwgkWYuAVQKU2oQCCnLx9NzbtvMtLIe4JRzoTa4LF-y3QM7pI-Vr2laEpR-0WZJKhRmr0ZipARYGuU-7CPFwZB2x8r6sgwHaUYb82UKWndycA3mt2svFoqRxi9WyhP-BFLYLqsBZBD74nhwdSwZwaGqUtezUSlmosgVatBjcpqUI9dNSgKfP-seeqgOKgPgVTIrJMufz7c7Nk-i6-ydfgYNsuYdFcUqnUKugtS2kbRf2Yi46aCmWl3cu1du1KR4RJtde10yfEqFNACFXO1QnX8v4Gq8lLbfGzVKHu_s1TCc4gIWbYC0N5-hg-gcTykXgwpBahiHwXhLF_Ek2ygw"

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: incorrectActivationToken
        )

        XCTAssertNil(user)
        assertError(current: regError, expected: RegistrationError.invalidActivationToken)
    }

    func testRandomActivationTokenFailedRegistration() throws {
        let randomActivationToken = UUID().uuidString

        let (user, regError) = registrationTestCase.registerUser(
            userId: userId,
            activationToken: randomActivationToken
        )

        XCTAssertNil(user)
        let error = try XCTUnwrap(regError)
        var isErrorCorrect = false
        if case let RegistrationError.registrationFail(underlyingError) = error, let underlyingError {
            if case let APIError.apiClientError(statusCode: _, clientErrorData: clientErrorData, requestId: _, message: _, requestURL: _) = underlyingError, let clientErrorData {
                isErrorCorrect = clientErrorData.code == INVALID_REQUEST_PARAMETERS
            }
        }

        XCTAssertTrue(isErrorCorrect)
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
            serviceAccountToken: serviceAccountToken,
            projectId: projectIdPV,
            projectURL: projectURL,
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
            serviceAccountToken: serviceAccountToken,
            projectId: projectIdPV,
            projectURL: projectURL,
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
        configuration = try Configuration
            .Builder(projectId: projectIdDV, projectURL: projectURL)
            .userStorage(userStorage: storage)
            .build()

        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (response, _) = getActivationTokenTestCase.getActivationToken(
            serviceAccountToken: serviceAccountToken,
            projectId: projectIdPV,
            projectURL: projectURL,
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
