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
    var signingSessionDetails: SigningSessionDetails?

    override func setUpWithError() throws {
        hashData = SignerTests.messageHash()

        signingUser = SignerTests.createUser()

        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString
            )
            .userStorage(userStorage: storage)
            .build()

        try MIRACLTrust.configure(with: configuration)
        try MIRACLTrust.getInstance().userStorage.add(user: signingUser)

        timestamp = Date()
        crypto = SignerTests.mockCrypto()
        didRequestSigningPinHandler = { processPinHandler in
            processPinHandler("1234")
        }
        authenticator = mockAuthenticator()
    }

    func testSiginigCorrectness() throws {
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

    func testSigningCorrectnessWithSigingSessionDetails() throws {
        let signingUser = signingUser
        let hashData = hashData

        signingSessionDetails = SigningSessionDetails(
            userId: UUID().uuidString,
            projectName: UUID().uuidString,
            projectLogoURL: UUID().uuidString,
            projectId: UUID().uuidString,
            pinLength: 4,
            verificationMethod: .standardEmail,
            verificationURL: UUID().uuidString,
            verificationCustomText: UUID().uuidString,
            identityTypeLabel: UUID().uuidString,
            quickCodeEnabled: true,
            limitQuickCodeRegistration: true,
            identityType: .email,
            sessionId: UUID().uuidString,
            signingHash: UUID().uuidString,
            signingDescription: UUID().uuidString,
            status: .signed,
            expireTime: Date()
        )

        mockAPI = MockAPI()
        mockAPI.signingSessionCompleterError = nil
        mockAPI.signingSessionCompleterResponse = SigningSessionCompleterResponse(status: "signed")
        mockAPI.signingSessionCompleterResultCall = .success

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

    func testSignatureActiveSessionError() throws {
        signingSessionDetails = createSigningSessionDetails()

        mockAPI = MockAPI()
        mockAPI.signingSessionCompleterError = nil
        mockAPI.signingSessionCompleterResponse = SigningSessionCompleterResponse(status: "active")
        mockAPI.signingSessionCompleterResultCall = .success

        let expectedError = SigningError.invalidSigningSession

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            assertError(current: error, expected: expectedError)
        }
    }

    func testSigningSignerForInvalidPIN() throws {
        didRequestSigningPinHandler = { processPinHandler in
            processPinHandler("OneTwoThree")
        }

        try testSigning { signature, error in
            XCTAssertNil(signature)
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, SigningError.invalidPin)
        }
    }

    func testSigningSignerForNilPIN() throws {
        didRequestSigningPinHandler = { processPinHandler in
            processPinHandler(nil)
        }

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, SigningError.pinCancelled)
        }
    }

    func testSigningSignerForCryptoError() throws {
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

    func testSigningSignerForInvalidUData() throws {
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

    func testSigningSignerForInvalidVData() throws {
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

    func testSigningSignerForInvalidVAndUData() throws {
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

    func testSigningSignerWithEmptyMessageHash() {
        guard let didRequestSigningPinHandler = didRequestSigningPinHandler else {
            XCTFail("Cannot create pin handler")
            return
        }

        XCTAssertThrowsError(try Signer(
            messageHash: Data(),
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

    func testSignerWithRevokedUser() {
        guard let didRequestSigningPinHandler = didRequestSigningPinHandler else {
            XCTFail("Cannot create pin handler")
            return
        }

        signingUser = SignerTests.createUser(revoked: true)

        XCTAssertThrowsError(try Signer(
            messageHash: Data(),
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

    func testSignerWithEmptySessionId() {
        guard let didRequestSigningPinHandler = didRequestSigningPinHandler else {
            XCTFail("Cannot create pin handler")
            return
        }

        signingSessionDetails = SigningSessionDetails(
            userId: UUID().uuidString,
            projectName: UUID().uuidString,
            projectLogoURL: UUID().uuidString,
            projectId: UUID().uuidString,
            pinLength: 4,
            verificationMethod: .standardEmail,
            verificationURL: UUID().uuidString,
            verificationCustomText: UUID().uuidString,
            identityTypeLabel: UUID().uuidString,
            quickCodeEnabled: true,
            limitQuickCodeRegistration: true,
            identityType: .email,
            sessionId: " ",
            signingHash: UUID().uuidString,
            signingDescription: UUID().uuidString,
            status: .signed,
            expireTime: Date()
        )

        XCTAssertThrowsError(try Signer(
            messageHash: hashData,
            user: XCTUnwrap(signingUser),
            signingSessionDetails: signingSessionDetails,
            crypto: crypto,
            didRequestSigningPinHandler: didRequestSigningPinHandler,
            completionHandler: { _, _ in
            }
        ), "Empty Session Id Error") { error in
            XCTAssertTrue(error is SigningError)
            XCTAssertEqual(error as? SigningError, SigningError.invalidSigningSessionDetails)
        }
    }

    func testSignerUnsuccesfulAuthentication() throws {
        let desiredError = SigningError.unsuccessfulAuthentication
        authenticator?.response = nil
        authenticator?.error = AuthenticationError.unsuccessfulAuthentication

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            assertError(current: error, expected: desiredError)
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

    func testSignerInvalidPin() throws {
        let desiredError = SigningError.invalidPin
        signingUser = SignerTests.createUser(pinLength: 10)

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

    func testSignatureWithSigingSessionDetailsNilResponse() throws {
        signingSessionDetails = createSigningSessionDetails()

        mockAPI = MockAPI()
        mockAPI.signingSessionCompleterError = nil
        mockAPI.signingSessionCompleterResponse = nil
        mockAPI.signingSessionCompleterResultCall = .success

        let expectedError = SigningError.signingFail(nil)

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            assertError(current: error, expected: expectedError)
        }
    }

    func testSignatureWithSigingSessionDetailsWithSessionError() throws {
        signingSessionDetails = createSigningSessionDetails()

        let wrappedError = APIError.apiServerError(statusCode: 503, message: nil, requestURL: nil)
        let expectedError = SigningError.signingFail(wrappedError)

        mockAPI = MockAPI()
        mockAPI.signingSessionCompleterError = wrappedError
        mockAPI.signingSessionCompleterResponse = nil
        mockAPI.signingSessionCompleterResultCall = .success

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            assertError(current: error, expected: expectedError)
        }
    }

    func testSignatureWithSigingSessionDetailsWithClientError() throws {
        signingSessionDetails = createSigningSessionDetails()

        let expectedError = SigningError.invalidSigningSession

        mockAPI = MockAPI()
        mockAPI.signingSessionCompleterError = apiClientError(
            with: INVALID_REQUEST_PARAMETERS,
            context: ["params": "id"]
        )
        mockAPI.signingSessionCompleterResponse = nil
        mockAPI.signingSessionCompleterResultCall = .success

        try testSigning { signatureResult, error in
            XCTAssertNil(signatureResult)
            assertError(current: error, expected: expectedError)
        }
    }

    // MARK: Test helper functions

    func testSigning(completionHandler: @escaping SigningCompletionHandler) throws {
        let waitForSigningOperationFinish = XCTestExpectation(description: "Signing Sign completion")

        do {
            guard let didRequestSigningPinHandler = didRequestSigningPinHandler else {
                XCTFail("Cannot create pin handler")
                return
            }

            var signer = try Signer(
                messageHash: hashData,
                user: XCTUnwrap(signingUser),
                signingSessionDetails: signingSessionDetails,
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
            XCTFail("Error when creating SigningSigner object.")
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
        let data = Data(iterator)
        return data
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

    func createSigningSessionDetails() -> SigningSessionDetails {
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
            quickCodeEnabled: true,
            limitQuickCodeRegistration: true,
            identityType: .email,
            sessionId: UUID().uuidString,
            signingHash: UUID().uuidString,
            signingDescription: UUID().uuidString,
            status: .signed,
            expireTime: Date()
        )
    }

    private func apiClientError(with code: String, context: [String: String]? = nil) -> APIError {
        let clientErrorData = ClientErrorData(
            code: code,
            info: "",
            context: context
        )

        return APIError.apiClientError(
            clientErrorData: clientErrorData,
            requestId: "",
            message: nil,
            requestURL: nil
        )
    }
}
