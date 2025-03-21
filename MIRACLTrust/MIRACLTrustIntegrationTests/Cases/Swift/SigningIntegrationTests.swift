import CryptoKit
import XCTest

@testable import MIRACLTrust

extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }
}

class SigningIntegrationTests: XCTestCase {
    var registration = RegistrationTestCase()
    var authentication = QRAuthenticationTestCase()
    var getActivationToken = GetActivationTokenTestCase()
    var signing = SigningTestCase()
    var signingSessionDetails = GetSigningSessionDetailsTestCase()

    var accessId = ""
    var activationToken = ""
    var configuration: Configuration?
    var registeredSigningUser: User?
    var timestamp = Date()
    var messageHash = Data()

    var storage = SQLiteUserStorage(
        projectId: ProcessInfo.processInfo.environment["projectIdCUV"]!,
        databaseName: testDBName
    )

    var messageToSign = UUID().uuidString

    let platformURL = ProcessInfo.processInfo.environment["platformURL"]!
    let projectId = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let clientId = ProcessInfo.processInfo.environment["clientIdCUV"]!
    let clientSecret = ProcessInfo.processInfo.environment["clientSecretCUV"]!

    let userId = "global@example.com"
    let randomPIN = String(Int32.random(in: 1000 ..< 9999))
    let randomSigningPIN = String(Int32.random(in: 1000 ..< 9999))
    let anotherRandomSigningPIN = String(Int32.random(in: 1000 ..< 9999))
    let api = PlatformAPIWrapper()

    override func setUpWithError() throws {
        try super.setUpWithError()

        timestamp = Date()
        registration = RegistrationTestCase()
        registration.pinCode = randomPIN

        authentication = QRAuthenticationTestCase()
        authentication.pinCode = randomPIN

        accessId = try XCTUnwrap(api.getAccessId(projectId: projectId))

        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(
                projectId: projectId,
                deviceName: UUID().uuidString
            ).userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (response, _) = getActivationToken.getActivationToken(
            clientId: clientId,
            clientSecret: clientSecret,
            projectId: projectId,
            userId: userId
        )

        activationToken = try XCTUnwrap(response?.activationToken)

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        registeredSigningUser = try XCTUnwrap(user)
        XCTAssertNil(regError)

        let qrCode = "https://mcl.mpin.io/mobile-login/#\(accessId)"
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            qrCode: qrCode
        )
        XCTAssertTrue(isAuthenticated)
        XCTAssertNil(authError)

        messageToSign = UUID().uuidString
        let messageData = try XCTUnwrap(messageToSign.data(using: .utf8))
        messageHash = SHA256.hash(data: messageData).data
        signing.signingPinCode = randomPIN
    }

    override func tearDown() {
        super.tearDown()
        do {
            let path = DBFileHelper.getDBFilePath()
            try FileManager.default.removeItem(atPath: path)
            XCTAssertFalse(FileManager.default.fileExists(atPath: path))
        } catch {
            XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
        }
    }

    func testSigningCorrectness() throws {
        let (signingResult, error) = try signing.signMessage(
            message: messageHash,
            user: XCTUnwrap(registeredSigningUser)
        )

        XCTAssertNil(error)

        let unwrappedSigningResult = try XCTUnwrap(signingResult)
        let isSignatureVerified = api.verifySignature(
            signingResult: unwrappedSigningResult,
            clientId: clientId,
            clientSecret: clientSecret,
            projectId: projectId
        )

        XCTAssertTrue(isSignatureVerified)
    }

    func testSigningCorrectnessWithSessionDetails() throws {
        let qrCode = try XCTUnwrap(
            api.startSigningSession(
                projectID: projectId,
                userID: userId,
                hash: UUID().uuidString,
                description: "Test transaction"
            )
        )

        var (signingSessionDetails, _) = signingSessionDetails.getSigningSessionDetails(qrCode: qrCode)
        signingSessionDetails = try XCTUnwrap(signingSessionDetails)

        let (signingResult, error) = try signing.signMessage(
            message: messageHash,
            user: XCTUnwrap(registeredSigningUser),
            signingSessionDetails: signingSessionDetails
        )

        XCTAssertNotNil(signingResult)
        XCTAssertNil(error)

        let unwrappedSigningResult = try XCTUnwrap(signingResult)
        let isSignatureVerified = api.verifySignature(
            signingResult: unwrappedSigningResult,
            clientId: clientId,
            clientSecret: clientSecret,
            projectId: projectId
        )

        XCTAssertTrue(isSignatureVerified)
    }

    func testSigningCorrectnessSHA384() throws {
        guard let messageData = messageToSign.data(using: .utf8) else {
            XCTFail("Cannot create data from message.")
            return
        }

        let messageHash = SHA384.hash(data: messageData).data
        let (signingResult, error) = try signing.signMessage(
            message: messageHash,
            user: XCTUnwrap(registeredSigningUser)
        )

        XCTAssertNil(error)

        let unwrappedSigningResult = try XCTUnwrap(signingResult)
        let isSignatureVerified = api.verifySignature(
            signingResult: unwrappedSigningResult,
            clientId: clientId,
            clientSecret: clientSecret,
            projectId: projectId
        )

        XCTAssertTrue(isSignatureVerified)
    }

    func testSigningEmptyMessageHash() throws {
        let messageHash = Data()

        let (signingResult, signingSigningError) = try signing.signMessage(
            message: messageHash,
            user: XCTUnwrap(registeredSigningUser)
        )

        XCTAssertNil(signingResult)
        XCTAssertNotNil(signingSigningError)

        XCTAssertTrue(signingSigningError is SigningError)
        XCTAssertEqual(signingSigningError as? SigningError, SigningError.emptyMessageHash)
    }

    func testSigningWrongPinAuthentication() throws {
        var differentPinCode = String(Int32.random(in: 1000 ..< 9999))
        if signing.signingPinCode == differentPinCode {
            differentPinCode = String(Int32.random(in: 1000 ..< 9999))
        }
        signing.signingPinCode = differentPinCode

        let (signingResult, signingError) = try signing.signMessage(
            message: messageHash,
            user: XCTUnwrap(registeredSigningUser)
        )

        XCTAssertNil(signingResult)
        XCTAssertNotNil(signingError)
        assertError(current: signingError, expected: SigningError.unsuccessfulAuthentication)
    }

    func testSigningInvalidPinAuthentication() throws {
        signing.signingPinCode = NSUUID().uuidString

        guard let messageData = messageToSign.data(using: .utf8) else {
            XCTFail("Cannot create data from message.")
            return
        }

        let messageHash = SHA256.hash(data: messageData).data

        let (signingResult, signingSigningError) = try signing.signMessage(
            message: messageHash,
            user: XCTUnwrap(registeredSigningUser)
        )

        XCTAssertNil(signingResult)
        XCTAssertTrue(signingSigningError is SigningError)
        XCTAssertEqual(signingSigningError as? SigningError, SigningError.invalidPin)
    }

    func testSigningInvalidPublicKey() throws {
        let registeredSigningUser = createRandomUser(publicKey: Data())

        try storage.update(user: registeredSigningUser)

        guard let messageData = messageToSign.data(using: .utf8) else {
            XCTFail("Cannot create data from message.")
            return
        }

        let messageHash = SHA256.hash(data: messageData).data

        let (signingResult, signingSigningError) = signing.signMessage(
            message: messageHash,
            user: registeredSigningUser
        )

        XCTAssertNil(signingResult)
        XCTAssertTrue(signingSigningError is SigningError)
        XCTAssertEqual(signingSigningError as? SigningError, SigningError.emptyPublicKey)
    }

    func testSigningRevokedUserErrorAfterThreeFailedAttempts() throws {
        signing.signingPinCode = anotherRandomSigningPIN

        var (signingResult, error) = try signing.signMessage(
            message: messageHash,
            user: XCTUnwrap(registeredSigningUser)
        )

        XCTAssertNil(signingResult)
        XCTAssertNotNil(error)

        (signingResult, error) = try signing.signMessage(
            message: messageHash,
            user: XCTUnwrap(registeredSigningUser)
        )

        XCTAssertNil(signingResult)
        XCTAssertNotNil(error)

        (signingResult, error) = try signing.signMessage(
            message: messageHash,
            user: XCTUnwrap(registeredSigningUser)
        )

        XCTAssertNil(signingResult)
        assertError(
            current: error,
            expected: SigningError.revoked
        )
    }

    func testSigningWithInvalidSessionDetails() throws {
        let sessionDetails = createRandomSigningSessionDetails()

        let expectedError = SigningError.invalidSigningSession

        let (signingResult, error) = try signing.signMessage(
            message: messageHash,
            user: XCTUnwrap(registeredSigningUser),
            signingSessionDetails: sessionDetails
        )

        XCTAssertNil(signingResult)
        assertError(current: error, expected: expectedError)
    }

    func testSigningWithEmptySessionDetails() throws {
        let sessionDetails = createRandomSigningSessionDetails(sessionId: "")

        let expectedError = SigningError.invalidSigningSessionDetails

        let (signingResult, error) = try signing.signMessage(
            message: messageHash,
            user: XCTUnwrap(registeredSigningUser),
            signingSessionDetails: sessionDetails
        )

        XCTAssertNil(signingResult)
        assertError(current: error, expected: expectedError)
    }

    private func createRandomSigningSessionDetails(
        sessionId: String = UUID().uuidString
    ) -> SigningSessionDetails {
        SigningSessionDetails(
            userId: UUID().uuidString,
            projectName: UUID().uuidString,
            projectLogoURL: UUID().uuidString,
            projectId: UUID().uuidString,
            pinLength: 4,
            verificationMethod: .standardEmail,
            verificationURL: UUID().uuidString,
            verificationCustomText: UUID().uuidString,
            identityTypeLabel: UUID().uuidString,
            quickCodeEnabled: Bool.random(),
            limitQuickCodeRegistration: Bool.random(),
            identityType: .alphanumeric,
            sessionId: sessionId,
            signingHash: UUID().uuidString,
            signingDescription: UUID().uuidString,
            status: .active,
            expireTime: Date()
        )
    }

    private func createRandomUser(publicKey: Data? = Data([1, 2, 3])) -> User {
        User(
            userId: UUID().uuidString,
            projectId: UUID().uuidString,
            revoked: false,
            pinLength: 4,
            mpinId: Data([1, 2, 3]),
            token: Data([1, 2, 3]),
            dtas: UUID().uuidString,
            publicKey: publicKey
        )
    }
}
