@testable import MIRACLTrust
import XCTest

class UniversalLinkAuthIntegrationTests: XCTestCase {
    var registration = RegistrationTestCase()
    var authentication = UniversalLinkAuthenticationTestCase()
    var getActivationToken = GetActivationTokenTestCase()
    var accessId = ""
    var qrCode = ""
    var universalLinkURL: URL?
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
        registration = RegistrationTestCase()
        registration.pinCode = randomPIN

        authentication = UniversalLinkAuthenticationTestCase()
        authentication.pinCode = randomPIN

        accessId = try XCTUnwrap(api.getAccessId(projectId: projectId))
        qrCode = "https://mcl.mpin.io/mobile-login/#\(accessId)"
        universalLinkURL = URL(string: qrCode)

        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectId)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (response, _) = getActivationToken.getActivationToken(clientId: clientId, clientSecret: clientSecret, projectId: projectId, userId: userId)

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

    func testSuccessfulAuthentication() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        let universalLinkURL = try XCTUnwrap(universalLinkURL)
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: universalLinkURL
        )
        XCTAssertTrue(isAuthenticated)
        XCTAssertNil(authError)
    }

    func testFailedAuthenticationWithEmptyAccessId() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        qrCode = "https://mcl.mpin.io/mobile-login/"
        universalLinkURL = URL(string: qrCode)
        let universalLinkURL = try XCTUnwrap(universalLinkURL)
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: universalLinkURL
        )
        XCTAssertFalse(isAuthenticated)

        assertError(
            current: authError,
            expected: AuthenticationError.invalidUniversalLink
        )
    }

    func testFailedAuthenticationWithInvalidAccessId() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        qrCode = "https://mcl.mpin.io/mobile-login/#xyzzz"
        universalLinkURL = URL(string: qrCode)
        let universalLinkURL = try XCTUnwrap(universalLinkURL)
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: universalLinkURL
        )
        XCTAssertFalse(isAuthenticated)
        assertError(current: authError, expected: AuthenticationError.invalidAuthenticationSession)
    }

    func testSuccessfulAuthenticationWithDifferentAccessId() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        let differentAccessId = try XCTUnwrap(api.getAccessId(projectId: projectId))
        qrCode = "https://mcl.mpin.io/mobile-login/#\(differentAccessId)"
        universalLinkURL = URL(string: qrCode)
        let universalLinkURL = try XCTUnwrap(universalLinkURL)
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: universalLinkURL
        )

        XCTAssertTrue(isAuthenticated)
        XCTAssertNil(authError)
    }

    func testFailedAuthenticationWithInvalidPin() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        authentication.pinCode = "InvalidPin"
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: XCTUnwrap(universalLinkURL)
        )

        XCTAssertFalse(isAuthenticated)

        assertError(
            current: authError,
            expected: AuthenticationError.invalidPin
        )
    }

    func testFailedAuthenticationWithDifferentPin() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        var differentPin = String(Int32.random(in: 1000 ..< 9999))
        if differentPin == authentication.pinCode {
            while authentication.pinCode == differentPin {
                differentPin = String(Int32.random(in: 1000 ..< 9999))
            }
        }

        authentication.pinCode = differentPin
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: XCTUnwrap(universalLinkURL)
        )

        XCTAssertFalse(isAuthenticated)
        assertError(current: authError, expected: AuthenticationError.unsuccessfulAuthentication)
    }

    func testFailedAuthenticationWithLongerPin() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        authentication.pinCode = String(Int32.random(in: 100_000 ..< 999_999))
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: XCTUnwrap(universalLinkURL)
        )

        XCTAssertFalse(isAuthenticated)
        assertError(current: authError, expected: AuthenticationError.invalidPin)
    }

    func testFailedAuthenticationWithShorterPin() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        authentication.pinCode = String(Int32.random(in: 100 ..< 999))
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: XCTUnwrap(universalLinkURL)
        )

        XCTAssertFalse(isAuthenticated)
        assertError(current: authError, expected: AuthenticationError.invalidPin)
    }

    func testFailedAuthenticationWithNilPin() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        authentication.pinCode = nil
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: XCTUnwrap(universalLinkURL)
        )

        XCTAssertFalse(isAuthenticated)
        assertError(current: authError, expected: AuthenticationError.pinCancelled)
    }

    func testFailedAuthenticationWithEmptyIdentity() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let emptyUser = createEmptyUser()

        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: emptyUser,
            universalLinkURL: XCTUnwrap(universalLinkURL)
        )

        XCTAssertFalse(isAuthenticated)
        assertError(
            current: authError,
            expected: AuthenticationError.invalidUserData
        )
    }

    private func createEmptyUser() -> User {
        User(
            userId: UUID().uuidString,
            projectId: UUID().uuidString,
            revoked: false,
            pinLength: 4,
            mpinId: Data(),
            token: Data(),
            dtas: "",
            publicKey: nil
        )
    }
}
