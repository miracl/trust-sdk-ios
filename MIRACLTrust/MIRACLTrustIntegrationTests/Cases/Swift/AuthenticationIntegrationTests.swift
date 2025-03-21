import JWTKit
@testable import MIRACLTrust
import XCTest

class AuthenticationIntegrationTests: XCTestCase {
    var registration = RegistrationTestCase()
    var authentication = QRAuthenticationTestCase()
    var jwtAuthenticationTestCase = JWTAuthenticationTestCase()
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

    let userId = "int@miracl.com"
    let randomPIN = String(Int32.random(in: 1000 ..< 9999))
    let api = PlatformAPIWrapper()

    override func setUpWithError() throws {
        registration = RegistrationTestCase()
        registration.pinCode = randomPIN

        jwtAuthenticationTestCase = JWTAuthenticationTestCase()
        jwtAuthenticationTestCase.pinCode = randomPIN

        accessId = try XCTUnwrap(api.getAccessId(projectId: projectId))

        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectId)
            .userStorage(userStorage: storage)
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

        authentication.pinCode = randomPIN
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

    func testSuccessfulJWTGeneration() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        let (jwt, jwtError) = try jwtAuthenticationTestCase.generateJWT(
            user: XCTUnwrap(user)
        )
        XCTAssertNil(jwtError)
        XCTAssertNotNil(jwt)

        let jwks = try XCTUnwrap(api.getJWKS())
        let signers = JWTSigners()
        try signers.use(jwksJSON: jwks)
        let payload = try signers.verify(jwt!, as: AuthenticationJWTPayload.self)

        XCTAssertEqual(payload.sub.value, userId)
        XCTAssertTrue(payload.aud.value.contains(projectId))
    }

    func testFailedJWTGenerationEmptyIdentity() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let emptyUser = createRandomUser(
            mpinId: Data(),
            token: Data(),
            dtas: ""
        )

        let (jwt, jwtError) = jwtAuthenticationTestCase.generateJWT(
            user: emptyUser
        )

        XCTAssertNil(jwt)
        assertError(current: jwtError, expected: AuthenticationError.invalidUserData)
    }

    func testFailedJWTGenerationDifferentPIN() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        var differentPin = String(Int32.random(in: 1000 ..< 9999))
        if differentPin == jwtAuthenticationTestCase.pinCode {
            while jwtAuthenticationTestCase.pinCode == differentPin {
                differentPin = String(Int32.random(in: 1000 ..< 9999))
            }
        }

        jwtAuthenticationTestCase.pinCode = differentPin

        let (jwt, jwtError) = try jwtAuthenticationTestCase.generateJWT(
            user: XCTUnwrap(user)
        )

        XCTAssertNil(jwt)
        assertError(current: jwtError, expected: AuthenticationError.unsuccessfulAuthentication)
    }

    func testFailedJWTShorterPINGeneration() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        jwtAuthenticationTestCase.pinCode = String(Int32.random(in: 100 ..< 999))
        let (jwtCode, jwtError) = try jwtAuthenticationTestCase.generateJWT(
            user: XCTUnwrap(user)
        )

        XCTAssertNil(jwtCode)
        assertError(current: jwtError, expected: AuthenticationError.invalidPin)
    }

    func testFailedJWTLongerPINGeneration() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        jwtAuthenticationTestCase.pinCode = String(Int32.random(in: 100_000 ..< 999_999))
        let (jwt, jwtError) = try jwtAuthenticationTestCase.generateJWT(
            user: XCTUnwrap(user)
        )
        XCTAssertNil(jwt)
        assertError(
            current: jwtError,
            expected: AuthenticationError.invalidPin
        )
    }

    func testFailedJWTNilPINGeneration() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        jwtAuthenticationTestCase.pinCode = nil
        let (jwt, jwtError) = try jwtAuthenticationTestCase.generateJWT(
            user: XCTUnwrap(user)
        )
        XCTAssertNil(jwt)
        assertError(
            current: jwtError,
            expected: AuthenticationError.pinCancelled
        )
    }

    func testRevokedIdentityJWTGeneration() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        var differentPin = String(Int32.random(in: 1000 ..< 9999))
        if differentPin == jwtAuthenticationTestCase.pinCode {
            while jwtAuthenticationTestCase.pinCode == differentPin {
                differentPin = String(Int32.random(in: 1000 ..< 9999))
            }
        }
        jwtAuthenticationTestCase.pinCode = differentPin

        // First try
        var (jwtCode, jwtError) = try jwtAuthenticationTestCase.generateJWT(user: XCTUnwrap(user))
        XCTAssertNil(jwtCode)
        assertError(current: jwtError, expected: AuthenticationError.unsuccessfulAuthentication)

        // Second try
        (jwtCode, jwtError) = try jwtAuthenticationTestCase.generateJWT(user: XCTUnwrap(user))
        XCTAssertNil(jwtCode)
        assertError(current: jwtError, expected: AuthenticationError.unsuccessfulAuthentication)

        // Third try. JWT generation should return an error that indicates for revoked identity.
        (jwtCode, jwtError) = try jwtAuthenticationTestCase.generateJWT(user: XCTUnwrap(user))
        XCTAssertNil(jwtCode)
        assertError(current: jwtError, expected: AuthenticationError.revoked)

        // After three unsuccessful tries, the user is blocked and cannot authenticate anymore.
        let qrCode = "https://mcl.mpin.io/mobile-login/#\(accessId)"
        let (authenticationResult, authenticationError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            qrCode: qrCode
        )

        let userId = try XCTUnwrap(user?.userId)
        let existingUser = try XCTUnwrap(MIRACLTrust.getInstance().getUser(by: userId))
        XCTAssertEqual(existingUser.revoked, true)

        XCTAssertFalse(authenticationResult)
        assertError(current: authenticationError, expected: AuthenticationError.revoked)
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
