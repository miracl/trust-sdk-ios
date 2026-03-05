@testable import MIRACLTrust
import XCTest

class UniversalLinkAuthIntegrationTests: XCTestCase {
    var registration = RegistrationTestCase()
    var authentication = UniversalLinkAuthenticationTestCase()
    var getActivationToken = GetActivationTokenTestCase()
    var qrCode = ""
    var universalLinkURL: URL?
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
        registration = RegistrationTestCase()
        registration.pinCode = randomPIN

        authentication = UniversalLinkAuthenticationTestCase()
        authentication.pinCode = randomPIN

        let accessId = try XCTUnwrap(api.startSession(projectId: projectId, projectURL: projectURL))
        qrCode = "https://mcl.mpin.io/mobile-login/#\(accessId.accessId)"
        universalLinkURL = URL(string: qrCode)

        configuration = try Configuration
            .Builder(projectId: projectId, projectURL: projectURL)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (response, _) = await getActivationToken.getActivationToken(
            serviceAccountToken: serviceAccountToken,
            projectId: projectId,
            projectURL: projectURL,
            userId: userId
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

    func testSuccessfulAuthentication() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        let universalLinkURL = try XCTUnwrap(universalLinkURL)
        let (isAuthenticated, authError) = try await authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: universalLinkURL
        )
        XCTAssertTrue(isAuthenticated)
        XCTAssertNil(authError)
    }

    func testFailedAuthenticationWithEmptyAccessId() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        qrCode = "https://mcl.mpin.io/mobile-login/"
        universalLinkURL = URL(string: qrCode)
        let universalLinkURL = try XCTUnwrap(universalLinkURL)
        let (isAuthenticated, authError) = try await authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: universalLinkURL
        )
        XCTAssertFalse(isAuthenticated)

        assertError(
            current: authError,
            expected: AuthenticationError.invalidUniversalLink
        )
    }

    func testFailedAuthenticationWithInvalidAccessId() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        qrCode = "https://mcl.mpin.io/mobile-login/#xyzzz"
        universalLinkURL = URL(string: qrCode)
        let universalLinkURL = try XCTUnwrap(universalLinkURL)
        let (isAuthenticated, authError) = try await authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: universalLinkURL
        )
        XCTAssertFalse(isAuthenticated)
        assertError(current: authError, expected: AuthenticationError.invalidAuthenticationSession)
    }

    func testSuccessfulAuthenticationWithDifferentAccessId() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        let differentAccessId = try XCTUnwrap(api.startSession(projectId: projectId, projectURL: projectURL)).accessId
        qrCode = "https://mcl.mpin.io/mobile-login/#\(differentAccessId)"
        universalLinkURL = URL(string: qrCode)
        let universalLinkURL = try XCTUnwrap(universalLinkURL)
        let (isAuthenticated, authError) = try await authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: universalLinkURL
        )

        XCTAssertTrue(isAuthenticated)
        XCTAssertNil(authError)
    }

    func testFailedAuthenticationWithInvalidPin() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        authentication.pinCode = "InvalidPin"
        let (isAuthenticated, authError) = try await authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: XCTUnwrap(universalLinkURL)
        )

        XCTAssertFalse(isAuthenticated)

        assertError(
            current: authError,
            expected: AuthenticationError.invalidPin
        )
    }

    func testFailedAuthenticationWithDifferentPin() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registration.registerUser(
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
        let (isAuthenticated, authError) = try await authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: XCTUnwrap(universalLinkURL)
        )

        XCTAssertFalse(isAuthenticated)
        assertError(current: authError, expected: AuthenticationError.unsuccessfulAuthentication)
    }

    func testFailedAuthenticationWithLongerPin() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        authentication.pinCode = String(Int32.random(in: 100_000 ..< 999_999))
        let (isAuthenticated, authError) = try await authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: XCTUnwrap(universalLinkURL)
        )

        XCTAssertFalse(isAuthenticated)
        assertError(current: authError, expected: AuthenticationError.invalidPin)
    }

    func testFailedAuthenticationWithShorterPin() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        authentication.pinCode = String(Int32.random(in: 100 ..< 999))
        let (isAuthenticated, authError) = try await authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: XCTUnwrap(universalLinkURL)
        )

        XCTAssertFalse(isAuthenticated)
        assertError(current: authError, expected: AuthenticationError.invalidPin)
    }

    func testFailedAuthenticationWithNilPin() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = await registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )

        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        authentication.pinCode = nil
        let (isAuthenticated, authError) = try await authentication.authenticateUser(
            user: XCTUnwrap(user),
            universalLinkURL: XCTUnwrap(universalLinkURL)
        )

        XCTAssertFalse(isAuthenticated)
        assertError(current: authError, expected: AuthenticationError.pinCancelled)
    }

    func testFailedAuthenticationWithEmptyIdentity() async throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let emptyUser = createEmptyUser()

        let (isAuthenticated, authError) = try await authentication.authenticateUser(
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
