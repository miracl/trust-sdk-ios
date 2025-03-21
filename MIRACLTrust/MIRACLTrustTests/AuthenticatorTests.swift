@testable import MIRACLTrust
import XCTest

class AuthenticatorTests: XCTestCase {
    var user = createUser()

    var accessId = NSUUID().uuidString
    var storage = MockUserStorage()
    var deviceName = NSUUID().uuidString
    var crypto = AuthenticatorTests.createValidMockCrypto()
    var api = MockAPI()
    var uuid = NSUUID()
    var scope = ["oidc"]
    var userId = UUID().uuidString
    var projectId = UUID().uuidString

    var didRequestPinHandler: PinRequestHandler = { processPinHandler in
        let randomNumber = Int32.random(in: 1000 ..< 9999)
        processPinHandler(String(randomNumber))
    }

    // MARK: Lifecycle

    override func setUp() {
        accessId = NSUUID().uuidString
        storage = MockUserStorage()
        deviceName = NSUUID().uuidString
        crypto = AuthenticatorTests.createValidMockCrypto()
        api = createMockAPI()

        do {
            let configuration = try Configuration
                .Builder(
                    projectId: projectId
                )
                .userStorage(userStorage: storage)
                .build()
            try MIRACLTrust.configure(with: configuration)

            user = AuthenticatorTests.createUser(userId: userId, projectId: projectId)

            try MIRACLTrust.getInstance().userStorage.add(user: user)
        } catch {
            XCTFail("Cannot create user and identity.")
        }
    }

    // MARK: Tests

    func testAuthentication() throws {
        try authenticate(completionHandler: { authenticationResponse, error in
            XCTAssertNotNil(authenticationResponse)
            XCTAssertNil(error)
        })
    }

    func testFailedAuthenticationForInvalidPinEntries() throws {
        didRequestPinHandler = { pinHandler in
            pinHandler("123")
        }

        try authenticate(completionHandler: { _, error in
            assertError(
                current: error,
                expected: AuthenticationError.invalidPin
            )
        })

        didRequestPinHandler = { pinHandler in
            pinHandler("12345")
        }

        try authenticate(completionHandler: { _, error in
            assertError(
                current: error,
                expected: AuthenticationError.invalidPin
            )
        })

        didRequestPinHandler = { pinHandler in
            pinHandler(nil)
        }

        try authenticate(completionHandler: { _, error in
            assertError(
                current: error,
                expected: AuthenticationError.pinCancelled
            )
        })

        didRequestPinHandler = { pinHandler in
            pinHandler(UUID().uuidString)
        }

        try authenticate(completionHandler: { _, error in
            assertError(
                current: error,
                expected: AuthenticationError.invalidPin
            )
        })
    }

    func testFailedAuthenticationForClientPass1Error() throws {
        let cryptoError = CryptoError.clientPass1Error(info: "")
        let desiredError = AuthenticationError.authenticationFail(cryptoError)
        crypto.clientPass1U = Data([])
        crypto.clientPass1S = Data([])
        crypto.clientPass1X = Data([])
        crypto.clientPass1Error = cryptoError

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationForErrorInServerPass1BadStatusCode() throws {
        let expectedError = APIError.apiServerError(statusCode: 500, message: nil, requestURL: nil)
        let desiredError = AuthenticationError.authenticationFail(expectedError)

        api.pass1Error = expectedError

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationForErrorInServerPass1MalformedJson() throws {
        let expectedError = APIError.apiMalformedJSON(nil, nil)
        let desiredError = AuthenticationError.authenticationFail(expectedError)

        api.pass1Error = expectedError

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationForMPinIDExpired() throws {
        let desiredError = AuthenticationError.revoked

        api.pass1Error = apiClientError(with: MPINID_EXPIRED)

        let storage = storage
        let projectId = projectId
        let userId = userId
        try authenticate(completionHandler: { response, error in
            do {
                XCTAssertNil(response)
                let user = try XCTUnwrap(storage.getUser(by: userId, projectId: projectId))
                XCTAssertTrue(user.revoked)
                assertError(
                    current: error,
                    expected: desiredError
                )
            } catch {
                XCTFail("Cannot unwrap revoked user")
            }
        })
    }

    func testFailedAuthenticationForExpiredMPinId() throws {
        let desiredError = AuthenticationError.revoked

        api.pass1Error = apiClientError(with: EXPIRED_MPINID)

        let storage = storage
        let projectId = projectId
        let userId = userId
        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)

            do {
                let user = try XCTUnwrap(storage.getUser(by: userId, projectId: projectId))
                XCTAssertTrue(user.revoked)
                assertError(
                    current: error,
                    expected: desiredError
                )
            } catch {
                XCTFail("Cannot unwrap revoked user")
            }

        })
    }

    func testFailedAuthenticationForUnexpectedAPIError() throws {
        let expectedError = apiClientError(with: "BACKOFF_ERROR")
        let desiredError = AuthenticationError.authenticationFail(expectedError)

        api.pass1Error = expectedError

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationInClientPass2ForCryptoError() throws {
        let cryptoError = CryptoError.clientPass2Error(info: "")
        let desiredError = AuthenticationError.authenticationFail(cryptoError)
        crypto.clientPass2Error = cryptoError
        crypto.clientPass2V = Data([])

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationInServerPass2ForBadStatusCode() throws {
        let expectedError = APIError.apiServerError(statusCode: 500, message: nil, requestURL: nil)
        let desiredError = AuthenticationError.authenticationFail(expectedError)

        api.pass2Error = expectedError

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationInServerPass2ForClientError() throws {
        let expectedError = apiClientError(with: "CUV_ERROR")

        let desiredError = AuthenticationError.authenticationFail(expectedError)

        api.pass2Error = expectedError

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationInAuthenticateCallBadStatusCode() throws {
        let expectedError = APIError.apiServerError(statusCode: 503, message: nil, requestURL: nil)
        let desiredError = AuthenticationError.authenticationFail(expectedError)

        api.authenticationResponseManager.authenticateError = expectedError

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationInAuthenticateClientError() throws {
        let expectedError = apiClientError(with: "CUV_ERROR")
        let desiredError = AuthenticationError.authenticationFail(expectedError)

        api.authenticationResponseManager.authenticateError = expectedError

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationInvalidAuthSession() throws {
        let desiredError = AuthenticationError.invalidAuthenticationSession

        api.authenticationResponseManager.authenticateError = apiClientError(with: INVALID_AUTH_SESSION)

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationInvalidAuthenticationSession() throws {
        let desiredError = AuthenticationError.invalidAuthenticationSession

        api.authenticationResponseManager.authenticateError = apiClientError(with: INVALID_AUTHENTICATION_SESSION)

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationRevokedUser() throws {
        let desiredError = AuthenticationError.revoked

        api.authenticationResponseManager.authenticateError = apiClientError(with: MPINID_REVOKED)

        let storage = storage
        let projectId = projectId
        let userId = userId
        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )

            do {
                let user = try XCTUnwrap(storage.getUser(by: userId, projectId: projectId))
                XCTAssertTrue(user.revoked)
            } catch {
                XCTFail("Cannot unwrap revoked user")
            }
        })
    }

    func testFailedAuthenticationRevokedMpinId() throws {
        let desiredError = AuthenticationError.revoked

        api.authenticationResponseManager.authenticateError = apiClientError(with: REVOKED_MPINID)

        let storage = storage
        let projectId = projectId
        let userId = userId
        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )

            do {
                let user = try XCTUnwrap(storage.getUser(by: userId, projectId: projectId))
                XCTAssertTrue(user.revoked)
                assertError(
                    current: error,
                    expected: desiredError
                )
            } catch {
                XCTFail("Cannot unwrap revoked user")
            }
        })
    }

    func testFailedAuthenticationInvalidAuth() throws {
        let desiredError = AuthenticationError.unsuccessfulAuthentication

        api.authenticationResponseManager.authenticateError = apiClientError(with: INVALID_AUTH)

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationUnsuccessfulAuthentication() throws {
        let desiredError = AuthenticationError.unsuccessfulAuthentication

        api.authenticationResponseManager.authenticateError = apiClientError(with: UNSUCCESSFUL_AUTHENTICATION)

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testFailedAuthenticationAuthenticateFailedOperation() throws {
        let desiredError = AuthenticationError.authenticationFail(nil)

        api.authenticationResponseManager.authenticateResponse = nil
        api.authenticationResponseManager.authenticateError = nil

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(
                current: error,
                expected: desiredError
            )
        })
    }

    func testWAM() throws {
        let mpinId = "7b22696174223a313632313431373839312c22757365724944223a22383631303732393532222c22634944223a2261623938653665382d326133652d346438632d623831322d323636306433633337373433222c2273616c74223a22486f7063634d7a6a794b53705279616d535333316351222c2276223a352c2273636f7065223a5b2261757468225d2c22647461223a5b5d2c227674223a227076227d"

        let dtas = "WyIyMDdiNWU5M2MxNTQ3YjY2ODY0MzUwNDIwZDU2MTU5MjVkODkyM2EyMWJkZDRlOTRmMzM0ZjViZWIxZDJhZjYxIiwiMThiYzUzYTQzY2VhOWM4MzE0MTRiYmFkZTE0NmE0NTcwNDJiMzNmYjQwN2ZiYzEzYjgyZWZhZjI4MTdmYjczOSJd"

        var signingClientSecret1Response = SigningClientSecret1Response()
        signingClientSecret1Response.mpinId = mpinId
        signingClientSecret1Response.dtas = dtas
        signingClientSecret1Response.signingClientSecretShare = UUID().uuidString
        signingClientSecret1Response.cs2URL = URL(string: "https://www.example.com")

        var renewSecretResponse = RenewSecretResponse()
        renewSecretResponse.token = UUID().uuidString

        var authenticateResponse = AuthenticateResponse()
        authenticateResponse.renewSecretResponse = renewSecretResponse

        api.authenticationResponseManager.authenticateError = nil
        api.authenticationResponseManager.authenticateResponse = authenticateResponse
        api.authenticationResponseManager.authenticateDVSAuth = true

        api.signingClientSecret1Error = nil
        api.signingClientSecret1Response = signingClientSecret1Response

        var clientSecretResponse = ClientSecretResponse()
        clientSecretResponse.dvsClientSecret = NSUUID().uuidString

        api.clientSecretResponse = clientSecretResponse

        let userId = userId
        let storage = storage
        try authenticate(completionHandler: { authenticationResponse, error in
            XCTAssertNotNil(authenticationResponse)
            XCTAssertNil(error)

            XCTAssertEqual(storage.all().count, 1)

            do {
                let currentUser = try XCTUnwrap(storage.all().first)

                XCTAssertEqual(currentUser.userId, userId)
                XCTAssertEqual(currentUser.mpinId.hex, mpinId)
                XCTAssertEqual(currentUser.token, Data([1, 2, 3]))
                XCTAssertEqual(currentUser.dtas, dtas)
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }
        })
    }

    func testAuthWithRevokedUser() {
        user = AuthenticatorTests.createUser(revoked: true)

        XCTAssertThrowsError(try authenticate(completionHandler: { _, _ in })) { error in
            assertError(current: error, expected: AuthenticationError.revoked)
        }
    }

    func testAuthenticationForPass2Error() throws {
        let wrappedError = APIError.apiClientError(
            clientErrorData: nil,
            requestId: "",
            message: nil,
            requestURL: nil
        )

        api.pass2Error = wrappedError
        api.pass2Response = nil
        api.pass2ResultCall = .failed

        try authenticate(completionHandler: { response, error in
            XCTAssertNil(response)
            assertError(current: error, expected: AuthenticationError.authenticationFail(wrappedError))
        })
    }

    // MARK: Private methods

    private func authenticate(completionHandler: @escaping AuthenticateCompletionHandler) throws {
        let expectation = XCTestExpectation(description: "Wait for Authentication.")
        let authenticator = try Authenticator(
            user: user,
            accessId: accessId,
            crypto: crypto,
            api: api,
            scope: scope,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { response, error in
                completionHandler(response, error)
                expectation.fulfill()
            }
        )
        authenticator.authenticate()
        wait(for: [expectation], timeout: 20.0)
    }

    private func createMockAPI() -> MockAPI {
        var pass1Response = Pass1Response()
        pass1Response.challenge = NSUUID().uuidString

        var pass2Response = Pass2Response()
        pass2Response.authOTT = NSUUID().uuidString

        var mockAPI = MockAPI()
        mockAPI.pass1Response = pass1Response

        mockAPI.pass2Response = pass2Response
        mockAPI.pass2Error = nil

        mockAPI.authenticationResponseManager.authenticateResponse = AuthenticateResponse()
        mockAPI.authenticationResponseManager.authenticateError = nil

        return mockAPI
    }

    class func createValidMockCrypto() -> MockCrypto {
        var crypto = MockCrypto()
        crypto.clientPass1U = Data([0, 1, 2, 3])
        crypto.clientPass1S = Data([4, 5, 6, 7])
        crypto.clientPass1X = Data([8, 9, 10, 11])

        crypto.clientPass2V = Data([11, 12, 13])

        crypto.clientTokenData = Data([1, 2, 3])

        crypto.keyPairError = nil
        crypto.publicKey = Data([127, 128])
        crypto.privateKey = Data([1, 10, 127, 127])

        crypto.signingClientTokenError = nil
        crypto.signingClientToken = Data([1, 2, 3])

        return crypto
    }

    class func createUser(
        userId: String = UUID().uuidString,
        projectId: String = UUID().uuidString,
        revoked: Bool = false
    ) -> User {
        User(
            userId: userId,
            projectId: projectId,
            revoked: revoked,
            pinLength: 4,
            mpinId: Data([1, 2, 3]),
            token: Data([3, 2, 1]),
            dtas: "dtas",
            publicKey: nil
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
