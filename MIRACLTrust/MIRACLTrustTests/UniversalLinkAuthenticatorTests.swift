@testable import MIRACLTrust
import XCTest

class UniversalLinkAuthenticatorTests: XCTestCase {
    var storage = MockUserStorage()
    var universalLinkURL = URL(string: "https://mcl.mpin.io#b227d0850d4280b98c5124a14aec84bf")
    var user: User?
    var deviceName = UUID().uuidString
    var authenticator: AuthenticatorBlueprint?
    var api = MockAPI()

    var didRequestPinHandler: PinRequestHandler = { pinHandler in
        let pinCode = Int.random(in: 1000 ..< 9999)
        pinHandler(String(pinCode))
    }

    override func setUpWithError() throws {
        storage = MockUserStorage()

        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString
            )
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: configuration)

        user = createUser()

        try MIRACLTrust.getInstance().userStorage.add(user: XCTUnwrap(user))

        authenticator = mockAuthenticator()
    }

    func testSuccessfulAuthentication() throws {
        try testUniversalLinkURLAuthentication { result, error in
            XCTAssertTrue(result)
            XCTAssertNil(error)
        }
    }

    func testAuthenticationMissingFragment() throws {
        universalLinkURL = URL(string: "https://mcl.mpin.io#")!
        try testUniversalLinkURLAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.invalidUniversalLink)
        }
    }

    func testAuthenticationEmptyUser() throws {
        user = createUser(userId: "", projectId: "")
        authenticator = nil

        try testUniversalLinkURLAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.invalidUserData)
        }
    }

    func testAuthenticationInvalidUser() throws {
        user = createUser(mpinId: Data(), token: Data())
        authenticator = nil

        try testUniversalLinkURLAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.invalidUserData)
        }
    }

    func testFailedAuthenticationShorterPin() throws {
        authenticator = nil
        didRequestPinHandler = { pinHandler in
            pinHandler("123")
        }

        try testUniversalLinkURLAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.invalidPin)
        }
    }

    func testFailedAuthenticationLongerPin() throws {
        authenticator = nil
        didRequestPinHandler = { pinHandler in
            pinHandler("1234567890")
        }

        try testUniversalLinkURLAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.invalidPin)
        }
    }

    func testFailedAuthenticationNilPin() throws {
        authenticator = nil
        didRequestPinHandler = { pinHandler in
            pinHandler(nil)
        }

        try testUniversalLinkURLAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.pinCancelled)
        }
    }

    // MARK: Private

    private func testUniversalLinkURLAuthentication(
        testCompletionHandler: @escaping AuthenticationCompletionHandler
    ) throws {
        let expectation = XCTestExpectation(description: "Wait for Universal link Authentication")

        var universalLinkAuthenticator = try UniversalLinkAuthenticator(
            user: XCTUnwrap(user),
            universalLinkURL: XCTUnwrap(universalLinkURL),
            deviceName: deviceName,
            miraclAPI: api,
            userStorage: storage,
            didRequestPinHandler: didRequestPinHandler
        ) { result, error in
            testCompletionHandler(result, error)
            expectation.fulfill()
        }
        universalLinkAuthenticator.authenticator = authenticator
        universalLinkAuthenticator.authenticate()

        let waitResult = XCTWaiter.wait(for: [expectation], timeout: 10.0)
        if waitResult != .completed {
            XCTFail("Failed expectation")
        }
    }

    private func mockAuthenticator() -> AuthenticatorBlueprint {
        let authenticateResponse = AuthenticateResponse()

        var mockAuthenticator = MockAuthenticator(completionHandler: { _, _ in })
        mockAuthenticator.error = nil
        mockAuthenticator.response = authenticateResponse

        return mockAuthenticator
    }

    private func createUser(
        userId: String = "example@example.com",
        projectId: String = UUID().uuidString,
        revoked: Bool = false,
        pinLength: Int = 4,
        mpinId: Data = Data([1, 2, 3]),
        token: Data = Data([3, 2, 1]),
        dtas: String = "dtas",
        publicKey: Data? = nil
    ) -> User {
        User(
            userId: userId,
            projectId: projectId,
            revoked: revoked,
            pinLength: pinLength,
            mpinId: mpinId,
            token: token,
            dtas: dtas,
            publicKey: publicKey
        )
    }
}
