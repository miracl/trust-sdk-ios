@testable import MIRACLTrust
import XCTest

final class CrossDeviceSessionAuthenticatorTest: XCTestCase {
    var storage = MockUserStorage()
    var crossDeviceSession: CrossDeviceSession?
    var user: User?
    var deviceName = UUID().uuidString
    var authenticator: AuthenticatorBlueprint?
    var api = MockAPI()
    var randomString = UUID().uuidString

    var didRequestPinHandler: PinRequestHandler = { pinHandler in
        let pinCode = Int.random(in: 1000 ..< 9999)
        pinHandler(String(pinCode))
    }

    override func setUpWithError() throws {
        storage = MockUserStorage()

        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString,
                projectURL: projectURL
            )
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: configuration)

        randomString = UUID().uuidString
        crossDeviceSession = CrossDeviceSession(
            userId: "",
            projectName: randomString,
            projectLogoURL: randomString,
            projectId: randomString,
            pinLength: 4,
            verificationMethod: .standardEmail,
            verificationURL: randomString,
            verificationCustomText: randomString,
            identityTypeLabel: randomString,
            quickCodeEnabled: true,
            identityType: .alphanumeric,
            sessionId: randomString,
            sessionDescription: "",
            signingHash: randomString
        )

        user = createUser()

        try MIRACLTrust.getInstance().userStorage.add(user: XCTUnwrap(user?.toUserDTO()))

        authenticator = mockAuthenticator()
    }

    func testSuccessfulAuthentication() throws {
        try testCrossDeviceSessionAuthentication { result, error in
            XCTAssertTrue(result)
            XCTAssertNil(error)
        }
    }

    func testAuthenticationInvalidUser() throws {
        user = createUser(mpinId: Data(), token: Data())
        authenticator = nil

        try testCrossDeviceSessionAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.invalidUserData)
        }
    }

    func testAuthenticationEmptyUser() throws {
        user = createUser(userId: "", projectId: "")
        authenticator = nil

        try testCrossDeviceSessionAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.invalidUserData)
        }
    }

    func testFailedAuthenticationShorterPin() throws {
        authenticator = nil
        didRequestPinHandler = { pinHandler in
            pinHandler("123")
        }

        try testCrossDeviceSessionAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.invalidPin)
        }
    }

    func testFailedAuthenticationLongerPin() throws {
        authenticator = nil
        didRequestPinHandler = { pinHandler in
            pinHandler("1234567890")
        }

        try testCrossDeviceSessionAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.invalidPin)
        }
    }

    // MARK: Private

    private func testCrossDeviceSessionAuthentication(
        testCompletionHandler: @escaping AuthenticationCompletionHandler
    ) throws {
        let expectation = XCTestExpectation(description: "Wait for QR Authentication")

        var crossDeviceSessionAuthenticator = try CrossDeviceSessionAuthenticator(
            user: XCTUnwrap(user),
            crossDeviceSession: XCTUnwrap(crossDeviceSession),
            didRequestPinHandler: didRequestPinHandler
        ) { result, error in
            testCompletionHandler(result, error)
            expectation.fulfill()
        }
        crossDeviceSessionAuthenticator.authenticator = authenticator
        crossDeviceSessionAuthenticator.authenticate()

        let waitResult = XCTWaiter.wait(for: [expectation], timeout: 10.0)
        if waitResult != .completed {
            XCTFail("Failed expectation")
        }
    }

    private func mockAuthenticator() -> MockAuthenticator {
        let authenticateResponse = AuthenticateResponse()

        var mockAuthenticator = MockAuthenticator(completionHandler: { _, _ in })
        mockAuthenticator.error = nil
        mockAuthenticator.response = authenticateResponse

        return mockAuthenticator
    }

    private func createUser(
        userId: String = UUID().uuidString,
        projectId: String = UUID().uuidString,
        mpinId: Data = Data([1, 2, 3]),
        token: Data = Data([3, 2, 1])
    ) -> User {
        User(
            userId: userId,
            projectId: projectId,
            revoked: false,
            pinLength: 4,
            mpinId: mpinId,
            token: token,
            dtas: "dtas",
            publicKey: nil
        )
    }
}
