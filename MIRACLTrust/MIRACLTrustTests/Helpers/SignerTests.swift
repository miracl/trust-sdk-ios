import CryptoKit
@testable import MIRACLTrust
import XCTest

class SignerTests: XCTestCase {
    var hashData = messageHash()
    var signingUser = createUser()
    var timestamp = Date()
    var crypto = mockCrypto()
    var didRequestSigningPinHandler: PinRequestHandler?
    var authenticator: MockAuthenticator?
    var storage = MockUserStorage()
    var mockAPI = MockAPI()
    var sessionIdentifier: String?

    override func setUpWithError() throws {
        try super.setUpWithError()

        sessionIdentifier = nil
        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString,
                projectURL: projectURL
            )
            .userStorage(userStorage: storage)
            .build()

        signingUser = SignerTests.createUser()
        try MIRACLTrust.configure(with: configuration)
        try MIRACLTrust.getInstance().userStorage.add(user: signingUser.toUserDTO())

        timestamp = Date()
        crypto = SignerTests.mockCrypto()
        didRequestSigningPinHandler = { processPinHandler in
            processPinHandler("1234")
        }
        authenticator = mockAuthenticator()
        hashData = SignerTests.messageHash()
    }

    func testSignerForNoSession() throws {
        let signingUser = signingUser
        let hashData = hashData
        try testSigning { signatureResult, error in
            XCTAssertNil(error)
            do {
                let signatureResult = try XCTUnwrap(signatureResult)
                let publicKey = try XCTUnwrap(signingUser.publicKey)

                XCTAssertEqual(signatureResult.signature.mpinId, signingUser.mpinId.hex)
                XCTAssertEqual(signatureResult.signature.U, Data([19, 20, 21]).hex)
                XCTAssertEqual(signatureResult.signature.V, Data([4, 5, 6]).hex)
                XCTAssertEqual(signatureResult.signature.publicKey, publicKey.hex)
                XCTAssertEqual(signatureResult.signature.dtas, signingUser.dtas)
                XCTAssertEqual(signatureResult.signature.signatureHash, hashData.hex)
                XCTAssertNotNil(signatureResult.timestamp)

            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }
        }
    }

    func testSignerForNonEmptySessionIdentifier() throws {
        sessionIdentifier = UUID().uuidString
        let signingUser = signingUser
        let hashData = hashData

        try testSigning { signatureResult, error in
            XCTAssertNil(error)
            do {
                let signatureResult = try XCTUnwrap(signatureResult)
                let publicKey = try XCTUnwrap(signingUser.publicKey)

                XCTAssertEqual(signatureResult.signature.mpinId, signingUser.mpinId.hex)
                XCTAssertEqual(signatureResult.signature.U, Data([19, 20, 21]).hex)
                XCTAssertEqual(signatureResult.signature.V, Data([4, 5, 6]).hex)
                XCTAssertEqual(signatureResult.signature.publicKey, publicKey.hex)
                XCTAssertEqual(signatureResult.signature.dtas, signingUser.dtas)
                XCTAssertEqual(signatureResult.signature.signatureHash, hashData.hex)
                XCTAssertNotNil(signatureResult.timestamp)

            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }
        }
    }

    func testSignerForInvalidPIN() throws {
        didRequestSigningPinHandler = { processPinHandler in
            processPinHandler("OneTwoThree")
        }

        try testSigning { signature, error in
            XCTAssertNil(signature)
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, SigningError.invalidPin)
        }
    }

    func testSignerForNilPIN() throws {
        didRequestSigningPinHandler = { processPinHandler in
            processPinHandler(nil)
        }

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, SigningError.pinCancelled)
        }
    }

    func testSignerRevokedUser() throws {
        let desiredError = SigningError.revoked

        authenticator?.response = nil
        authenticator?.error = AuthenticationError.revoked

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            assertError(current: error, expected: desiredError)
        }
    }

    func testSignerUnsuccessfulAuthentication() throws {
        let desiredError = SigningError.unsuccessfulAuthentication

        authenticator?.response = nil
        authenticator?.error = AuthenticationError.unsuccessfulAuthentication

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            assertError(current: error, expected: desiredError)
        }
    }

    func testSignerAuthenticationFail() throws {
        let wrappedError = APIError.executionError("Something went wrong", nil)
        let desiredError = SigningError.signingFail(AuthenticationError.authenticationFail(wrappedError))

        authenticator?.response = nil
        authenticator?.error = AuthenticationError.authenticationFail(wrappedError)

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            assertError(current: error, expected: desiredError)
        }
    }

    func testSignerNilPublicKey() throws {
        let desiredError = SigningError.emptyPublicKey
        signingUser = SignerTests.createUser(publicKey: nil)

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            assertError(current: error, expected: desiredError)
        }
    }

    func testSignerForCryptoError() throws {
        let expectedError = CryptoError.getClientTokenError(info: "")
        let desiredError = SigningError.signingFail(expectedError)

        crypto.signError = expectedError
        crypto.signMessageU = Data()
        crypto.signMessageV = Data()

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, desiredError)
        }
    }

    func testSignerForEmptyData() throws {
        let desiredError = SigningError.signingFail(nil)

        crypto.signMessageU = Data()
        crypto.signMessageV = Data()

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, desiredError)
        }
    }

    func testSignerForInvalidUData() throws {
        let expectedError = SigningError.signingFail(nil)

        crypto.signError = nil
        crypto.signMessageU = Data()
        crypto.signMessageV = Data([1, 2, 3])

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, expectedError)
        }
    }

    func testSignerForInvalidVData() throws {
        let expectedError = SigningError.signingFail(nil)

        crypto.signError = nil
        crypto.signMessageU = Data([1, 2, 3])
        crypto.signMessageV = Data()

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, expectedError)
        }
    }

    func testSignerForInvalidVAndUData() throws {
        let expectedError = SigningError.signingFail(nil)

        crypto.signError = nil
        crypto.signMessageU = Data()
        crypto.signMessageV = Data()

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, expectedError)
        }
    }

    func testSignerForJsonEncodingError() {}

    func testSignerForCompleteCrossDeviceSessionRequest() throws {
        sessionIdentifier = UUID().uuidString

        let wrappedError = APIError.executionError("Something went wrong", nil)
        let expectedError = SigningError.signingFail(wrappedError)

        mockAPI.updateCrossDeviceSessionError = wrappedError
        mockAPI.updateCrossDeviceSessionResponse = nil

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, expectedError)
        }
    }

    func testSignerWithRevokedUser() {
        guard let didRequestSigningPinHandler = didRequestSigningPinHandler else {
            XCTFail("Cannot create pin handler")
            return
        }

        signingUser = SignerTests.createUser(revoked: true)

        XCTAssertThrowsError(try Signer(
            messageHash: Data(),
            sessionIdentifier: sessionIdentifier,
            user: XCTUnwrap(signingUser),
            crypto: crypto,
            didRequestSigningPinHandler: didRequestSigningPinHandler,
            completionHandler: { _, _ in
            }
        ), "Empty Access Id Error") { error in
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, SigningError.revoked)
        }
    }

    func testSignerWithEmptyUser() {
        guard let didRequestSigningPinHandler = didRequestSigningPinHandler else {
            XCTFail("Cannot create pin handler")
            return
        }

        signingUser = User(
            userId: "example@example.com",
            projectId: UUID().uuidString,
            revoked: false,
            pinLength: 4,
            mpinId: Data(),
            token: Data([3, 2, 1]),
            dtas: "",
            publicKey: Data([9, 10, 11])
        )
        authenticator = nil

        XCTAssertThrowsError(try Signer(
            messageHash: Data(),
            sessionIdentifier: sessionIdentifier,
            user: XCTUnwrap(signingUser),
            crypto: crypto,
            didRequestSigningPinHandler: didRequestSigningPinHandler,
            completionHandler: { _, _ in
            }
        ), "Empty Access Id Error") { error in
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, SigningError.invalidUserData)
        }
    }

    func testSignerWithEmptyPublicKey() {
        guard let didRequestSigningPinHandler = didRequestSigningPinHandler else {
            XCTFail("Cannot create pin handler")
            return
        }

        signingUser = User(
            userId: "example@example.com",
            projectId: UUID().uuidString,
            revoked: false,
            pinLength: 4,
            mpinId: Data([1, 2, 3]),
            token: Data([3, 2, 1]),
            dtas: UUID().uuidString,
            publicKey: Data()
        )

        XCTAssertThrowsError(try Signer(
            messageHash: hashData,
            sessionIdentifier: sessionIdentifier,
            user: XCTUnwrap(signingUser),
            crypto: crypto,
            didRequestSigningPinHandler: didRequestSigningPinHandler,
            completionHandler: { _, _ in
            }
        ), "Empty Access Id Error") { error in
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, SigningError.emptyPublicKey)
        }
    }

    func testSigningSignerWithEmptyMessageHash() {
        guard let didRequestSigningPinHandler = didRequestSigningPinHandler else {
            XCTFail("Cannot create pin handler")
            return
        }

        XCTAssertThrowsError(try Signer(
            messageHash: Data(),
            sessionIdentifier: sessionIdentifier,
            user: XCTUnwrap(signingUser),
            crypto: crypto,
            didRequestSigningPinHandler: didRequestSigningPinHandler,
            completionHandler: { _, _ in
            }
        ), "Empty Access Id Error") { error in
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, SigningError.emptyMessageHash)
        }
    }

    // MARK: Private

    func testSigning(completionHandler: @escaping SigningCompletionHandler) throws {
        let waitForSigningOperationFinish = XCTestExpectation(description: "Signing Sign completion")
        do {
            guard let didRequestSigningPinHandler = didRequestSigningPinHandler else {
                XCTFail("Cannot create pin handler")
                return
            }

            var signer = try Signer(
                messageHash: hashData,
                sessionIdentifier: sessionIdentifier,
                user: XCTUnwrap(signingUser),
                miraclAPI: mockAPI,
                crypto: crypto,
                didRequestSigningPinHandler: didRequestSigningPinHandler,
                completionHandler: { signature, error in
                    waitForSigningOperationFinish.fulfill()
                    completionHandler(signature, error)
                }
            )

            guard authenticator != nil else {
                XCTFail("Cannot create authenticator")
                return
            }

            signer.authenticator = authenticator
            signer.sign()
            let waitResult = XCTWaiter.wait(for: [waitForSigningOperationFinish], timeout: 10.0)
            if waitResult != .completed {
                XCTFail("Failed expectation")
            }

        } catch {
            XCTFail("Error when creating Signer object.")
        }
    }

    class func createUser(
        revoked: Bool = false,
        pinLength: Int = 4,
        publicKey: Data? = Data([9, 10, 11])
    ) -> User {
        User(
            userId: "example@example.com",
            projectId: UUID().uuidString,
            revoked: revoked,
            pinLength: pinLength,
            mpinId: Data([1, 2, 3]),
            token: Data([3, 2, 1]),
            dtas: "dtas",
            publicKey: publicKey
        )
    }

    class func messageHash() -> Data {
        let messageData = Data("Some nice string".utf8)
        let iterator = SHA256.hash(data: messageData).makeIterator()
        return Data(iterator)
    }

    func mockAuthenticator() -> MockAuthenticator {
        let authenticateResponse = AuthenticateResponse()

        var mockAuthenticator = MockAuthenticator(
            completionHandler: { _, _ in }
        )
        mockAuthenticator.error = nil
        mockAuthenticator.response = authenticateResponse

        return mockAuthenticator
    }

    class func mockCrypto() -> MockCrypto {
        var mockCrypto = MockCrypto()

        mockCrypto.signError = nil
        mockCrypto.signMessageU = Data([19, 20, 21])
        mockCrypto.signMessageV = Data([4, 5, 6])

        return mockCrypto
    }

    private func apiClientError(with code: String, context: [String: String]? = nil) -> APIError {
        let clientErrorData = ClientErrorData(
            code: code,
            info: "",
            context: context
        )

        return APIError.apiClientError(
            statusCode: 400,
            clientErrorData: clientErrorData,
            requestId: "",
            message: nil,
            requestURL: nil
        )
    }
}
