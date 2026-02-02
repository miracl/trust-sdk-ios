import CryptoKit
import JWTKit
@testable import MIRACLTrust
import XCTest

class SigningIntegrationTests: XCTestCase {
    var registration = RegistrationTestCase()
    var authentication = QRAuthenticationTestCase()
    var getActivationToken = GetActivationTokenTestCase()
    var signing = SigningTestCase()
    var crossDeviceSession = GetCrossDeviceSessionTestCase()

    var session: StartSessionResult?
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

    let projectURL = ProcessInfo.processInfo.environment["projectURLCUV"]!
    let projectId = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let serviceAccountToken = ProcessInfo.processInfo.environment["serviceAccountTokenCUV"]!

    let userId = "global@example.com"
    let randomPIN = String(Int32.random(in: 1000 ..< 9999))
    let randomSigningPIN = String(Int32.random(in: 1000 ..< 9999))
    let anotherRandomSigningPIN = String(Int32.random(in: 1000 ..< 9999))
    let api = PlatformAPIWrapper()

    override func setUpWithError() throws {
        try super.setUpWithError()

        registration = RegistrationTestCase()
        registration.pinCode = randomPIN

        authentication = QRAuthenticationTestCase()
        authentication.pinCode = randomPIN

        session = api.startSession(projectId: projectId, projectURL: projectURL)
        let session = try XCTUnwrap(session)

        configuration = try Configuration
            .Builder(
                projectId: projectId,
                projectURL: projectURL,
                deviceName: UUID().uuidString
            ).userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (response, _) = getActivationToken.getActivationToken(
            serviceAccountToken: serviceAccountToken,
            projectId: projectId,
            projectURL: projectURL,
            userId: userId
        )

        activationToken = try XCTUnwrap(response?.activationToken)

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        registeredSigningUser = try XCTUnwrap(user)
        XCTAssertNil(regError)

        let qrCode = "https://mcl.mpin.io/mobile-login/#\(session.accessId)"
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
        XCTAssertEqual(messageHash.hex, unwrappedSigningResult.signature.signatureHash)

        let verifySigningResponse = try XCTUnwrap(
            api.verifySignature(
                signingResult: unwrappedSigningResult,
                serviceAccountToken: serviceAccountToken,
                projectId: projectId,
                projectURL: projectURL
            )
        )

        let jwks = try String(contentsOf: XCTUnwrap(URL(string: "\(projectURL)/dvs/jwks")))
        let signers = JWTSigners()
        try signers.use(jwksJSON: jwks)
        let payload = try signers.verify(verifySigningResponse.certificate, as: SignatureCertificateJWTPayload.self)

        XCTAssertEqual(messageHash.hex, payload.hash)
    }

    func testSigningCorrectnessWithCrossDeviceSession() async throws {
        let session = try XCTUnwrap(
            api.startSession(
                projectId: projectId,
                projectURL: projectURL,
                userId: userId,
                hash: messageToSign.toHexString(),
                description: UUID().uuidString
            )
        )
        let qrCode = "tcb.miracl.app/mobile/sign#\(session.accessId)"
        let (crossDeviceSession, _) = crossDeviceSession.getCrossDeviceSession(qrCode: qrCode)

        let crossDeviceSessionUnwrap = try XCTUnwrap(crossDeviceSession)
        let (signingResult, error) = try signing.signMessage(
            crossDeviceSession: crossDeviceSessionUnwrap,
            user: XCTUnwrap(registeredSigningUser)
        )

        XCTAssertTrue(signingResult)
        XCTAssertNil(error)

        let sessionStatusResult = try await api.getSessionStatus(
            projectURL: projectURL,
            webOTT: session.webOTT
        )
        let sessionStatusResultResponse = try XCTUnwrap(sessionStatusResult.signature.fromBase64())
        let signature = try JSONDecoder().decode(Signature.self, from: XCTUnwrap(sessionStatusResultResponse.data(using: .utf8)))
        XCTAssertEqual(crossDeviceSessionUnwrap.signingHash, signature.signatureHash)

        let timeInterval = TimeInterval(signature.timestamp)
        let date = Date(timeIntervalSince1970: timeInterval)

        let verifySigningResponse = try XCTUnwrap(
            api.verifySignature(
                signature: signature,
                timestamp: date,
                serviceAccountToken: serviceAccountToken,
                projectId: projectId,
                projectURL: projectURL
            )
        )

        let jwks = try String(contentsOf: XCTUnwrap(URL(string: "\(projectURL)/dvs/jwks")))
        let signers = JWTSigners()
        try signers.use(jwksJSON: jwks)
        let payload = try signers.verify(verifySigningResponse.certificate, as: SignatureCertificateJWTPayload.self)

        XCTAssertEqual(signature.signatureHash, payload.hash)
    }

    func testSigningCorrectnessWithCrossDeviceSessionForUniversalLink() throws {
        let sessionId = try XCTUnwrap(
            api.startSession(projectId: projectId, projectURL: projectURL, userId: userId, hash: messageToSign, description: UUID().uuidString)
        ).accessId
        let universalLinkURL = try XCTUnwrap(URL(string: "https://mcl.mpin.io/mobile/sign#\(sessionId)"))
        let (crossDeviceSession, _) = crossDeviceSession.getCrossDeviceSession(universalLinkURL: universalLinkURL)

        let (signingResult, error) = try signing.signMessage(
            crossDeviceSession: XCTUnwrap(crossDeviceSession),
            user: XCTUnwrap(registeredSigningUser)
        )

        XCTAssertTrue(signingResult)
        XCTAssertNil(error)
    }

    func testSigningCorrectnessWithCrossDeviceSessionForPayload() throws {
        let sessionId = try XCTUnwrap(
            api.startSession(projectId: projectId, projectURL: projectURL, userId: userId, hash: messageToSign, description: UUID().uuidString)
        ).accessId
        let payload = ["qrURL": "https://mcl.mpin.io/mobile/sign#\(sessionId)"]

        let (crossDeviceSession, _) = crossDeviceSession.getCrossDeviceSession(pushNotificationPayload: payload)

        let (signingResult, error) = try signing.signMessage(
            crossDeviceSession: XCTUnwrap(crossDeviceSession),
            user: XCTUnwrap(registeredSigningUser)
        )

        XCTAssertTrue(signingResult)
        XCTAssertNil(error)
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
        XCTAssertEqual(messageHash.hex, unwrappedSigningResult.signature.signatureHash)

        let verifySigningResponse = try XCTUnwrap(
            api.verifySignature(
                signingResult: unwrappedSigningResult,
                serviceAccountToken: serviceAccountToken,
                projectId: projectId,
                projectURL: projectURL
            )
        )

        let jwks = try String(contentsOf: XCTUnwrap(URL(string: "\(projectURL)/dvs/jwks")))
        let signers = JWTSigners()
        try signers.use(jwksJSON: jwks)
        let payload = try signers.verify(verifySigningResponse.certificate, as: SignatureCertificateJWTPayload.self)

        XCTAssertEqual(messageHash.hex, payload.hash)
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

        try storage.update(user: registeredSigningUser.toUserDTO())

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

    // MARK: Private

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
