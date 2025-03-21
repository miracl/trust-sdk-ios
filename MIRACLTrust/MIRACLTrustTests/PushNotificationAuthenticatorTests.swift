@testable import MIRACLTrust
import XCTest

class PushNotificationAuthenticatorTests: XCTestCase {
    var storage = MockUserStorage()
    var payload = [AnyHashable: Any]()
    var user: User?
    var deviceName = UUID().uuidString
    var authenticator: AuthenticatorBlueprint?
    var api = MockAPI()

    var qrURL = "https://mcl.mpin.io#b227d0850d4280b98c5124a14aec84bf"
    var userId = UUID().uuidString
    var projectId = UUID().uuidString

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
        try MIRACLTrust.getInstance().userStorage.add(user: createUser())

        authenticator = mockAuthenticator()
        payload = [
            "userID": userId,
            "projectID": projectId,
            "qrURL": qrURL
        ]
    }

    func testSuccessfulAuthentication() {
        testPushNotificationPayloadAuthentication { result, error in
            XCTAssertTrue(result)
            XCTAssertNil(error)
        }
    }

    func testFailedAuthenticationInvalidUserId() {
        payload = [
            "projectID": projectId,
            "qrURL": qrURL
        ]

        testPushNotificationPayloadAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(
                current: error,
                expected: AuthenticationError.invalidPushNotificationPayload
            )
        }
    }

    func testFailedAuthenticationEmptyUserId() {
        payload = [
            "userID": "",
            "projectID": projectId,
            "qrURL": qrURL
        ]

        testPushNotificationPayloadAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(
                current: error,
                expected: AuthenticationError.invalidPushNotificationPayload
            )
        }
    }

    func testFailedAuthenticationInvalidProjectId() {
        payload = [
            "userID": userId,
            "qrURL": qrURL
        ]

        testPushNotificationPayloadAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(
                current: error,
                expected: AuthenticationError.invalidPushNotificationPayload
            )
        }
    }

    func testFailedAuthenticationEmptyProjectId() {
        payload = [
            "userID": userId,
            "projectID": "",
            "qrURL": qrURL
        ]

        testPushNotificationPayloadAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(
                current: error,
                expected: AuthenticationError.invalidPushNotificationPayload
            )
        }
    }

    func testFailedAuthenticationNoUser() {
        payload = [
            "userID": userId,
            "projectID": NSUUID().uuidString,
            "qrURL": qrURL
        ]

        testPushNotificationPayloadAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(
                current: error,
                expected: AuthenticationError.userNotFound
            )
        }
    }

    func testFailedAuthenticationInvalidAccessId() {
        payload = [
            "userID": userId,
            "projectID": projectId,
            "qrURL": "https://mcl.mpin.io"
        ]

        testPushNotificationPayloadAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(
                current: error,
                expected: AuthenticationError.invalidPushNotificationPayload
            )
        }
    }

    func testFailedAuthenticationShorterPin() {
        authenticator = nil
        didRequestPinHandler = { pinHandler in
            pinHandler("123")
        }

        testPushNotificationPayloadAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.invalidPin)
        }
    }

    func testFailedAuthenticationLongerPin() {
        authenticator = nil
        didRequestPinHandler = { pinHandler in
            pinHandler("1234567890")
        }

        testPushNotificationPayloadAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.invalidPin)
        }
    }

    func testFailedAuthenticationNilPin() {
        authenticator = nil
        didRequestPinHandler = { pinHandler in
            pinHandler(nil)
        }

        testPushNotificationPayloadAuthentication { result, error in
            XCTAssertFalse(result)
            assertError(current: error, expected: AuthenticationError.pinCancelled)
        }
    }

    // MARK: Private

    private func testPushNotificationPayloadAuthentication(
        testCompletionHandler: @escaping AuthenticationCompletionHandler
    ) {
        let expectation = XCTestExpectation(description: "Wait for Universal link Authentication")

        var pushNotificationsAuthenticator = PushNotificationAuthenticator(
            deviceName: deviceName,
            miraclAPI: api,
            userStorage: storage,
            didRequestPinHandler: didRequestPinHandler
        ) { result, error in
            testCompletionHandler(result, error)
            expectation.fulfill()
        }

        pushNotificationsAuthenticator.authenticator = authenticator
        pushNotificationsAuthenticator.authenticate(with: payload)

        let waitResult = XCTWaiter.wait(for: [expectation], timeout: 10.0)
        if waitResult != .completed {
            XCTFail("Failed expectation")
        }
    }

    private func mockAuthenticator() -> MockAuthenticator {
        let authenticateResponse = AuthenticateResponse()

        var mockAuthenticator = MockAuthenticator(
            completionHandler: { _, _ in }
        )
        mockAuthenticator.error = nil
        mockAuthenticator.response = authenticateResponse

        return mockAuthenticator
    }

    private func createUser() -> User {
        User(
            userId: userId,
            projectId: projectId,
            revoked: false,
            pinLength: 4,
            mpinId: Data([1, 2, 3]),
            token: Data([3, 2, 1]),
            dtas: "dtas",
            publicKey: nil
        )
    }
}
