@testable import MIRACLTrust
import XCTest

class QRAuthenticationIntegrationTests: XCTestCase {
    let platformURL = ProcessInfo.processInfo.environment["platformURL"]!

    var registration = RegistrationTestCase()
    var authentication = QRAuthenticationTestCase()
    var getActivationToken = GetActivationTokenTestCase()
    var accessId = ""
    var qrCode = ""
    var activationToken = ""
    var configuration: Configuration?

    var storage = SQLiteUserStorage(
        projectId: ProcessInfo.processInfo.environment["projectIdCUV"]!,
        databaseName: testDBName
    )

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

        authentication = QRAuthenticationTestCase()
        authentication.pinCode = randomPIN

        accessId = try XCTUnwrap(api.getAccessId(projectId: projectId))
        qrCode = "https://mcl.mpin.io/mobile-login/#\(accessId)"

        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(
                projectId: projectId
            ).userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

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

    func testSuccessfulAuthentication() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            qrCode: qrCode
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

        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            qrCode: ""
        )
        XCTAssertFalse(isAuthenticated)

        assertError(
            current: authError,
            expected: AuthenticationError.invalidQRCode
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

        qrCode = "https://mcl.mpin.io/mobile-login/#invalidAccessId"
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            qrCode: qrCode
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
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            qrCode: qrCode
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
            qrCode: qrCode
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
            qrCode: qrCode
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
            qrCode: qrCode
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
            qrCode: qrCode
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
            qrCode: qrCode
        )

        XCTAssertFalse(isAuthenticated)
        assertError(current: authError, expected: AuthenticationError.pinCancelled)
    }

    func testFailedAuthenticationWithEmptyIdentity() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let emptyUser = createRandomUser(
            mpinId: Data(),
            token: Data(),
            dtas: ""
        )

        let (isAuthenticated, authError) = authentication.authenticateUser(
            user: emptyUser,
            qrCode: qrCode
        )

        XCTAssertFalse(isAuthenticated)
        assertError(
            current: authError,
            expected: AuthenticationError.invalidUserData
        )
    }

    private func createRandomUser(
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
