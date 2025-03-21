@testable import MIRACLTrust
import XCTest

class PushNotificationsIntegrationTest: XCTestCase {
    var registration = RegistrationTestCase()
    var authentication = PushNotificationsAuthenticationTestCase()
    var getActivationToken = GetActivationTokenTestCase()

    var qrURL = ""
    var payload = [AnyHashable: Any]()
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

    let userId = "global@example.com"
    let randomPIN = String(Int32.random(in: 1000 ..< 9999))
    let api = PlatformAPIWrapper()

    override func setUpWithError() throws {
        try super.setUpWithError()

        registration = RegistrationTestCase()
        registration.pinCode = randomPIN

        authentication = PushNotificationsAuthenticationTestCase()
        authentication.pinCode = randomPIN

        let accessId = try XCTUnwrap(api.getAccessId(projectId: projectId))
        qrURL = "https://mcl.mpin.io/mobile-login/#\(accessId)"
        payload = [
            "userID": userId,
            "projectID": projectId,
            "qrURL": qrURL
        ]

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
            pushPayload: payload
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

        payload = [
            "userID": userId,
            "projectID": projectId,
            "qrURL": ""
        ]

        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            pushPayload: payload
        )
        XCTAssertFalse(isAuthenticated)

        assertError(
            current: authError,
            expected: AuthenticationError.invalidPushNotificationPayload
        )
    }

    func testFailedAuthenticationCannotFetchUser() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        payload = [
            "userID": "userId",
            "projectID": "projectId",
            "qrURL": qrURL
        ]

        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            pushPayload: payload
        )
        XCTAssertFalse(isAuthenticated)

        assertError(
            current: authError,
            expected: AuthenticationError.userNotFound
        )
    }

    func testFailedAuthenticationWithEmptyProjectId() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        payload = [
            "userID": userId,
            "projectID": "",
            "qrURL": qrURL
        ]

        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            pushPayload: payload
        )
        XCTAssertFalse(isAuthenticated)

        assertError(
            current: authError,
            expected: AuthenticationError.invalidPushNotificationPayload
        )
    }

    func testFailedAuthenticationWithEmptyUserId() throws {
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (user, regError) = registration.registerUser(
            userId: userId,
            activationToken: activationToken
        )
        XCTAssertNil(regError)
        XCTAssertNotNil(user)

        payload = [
            "userID": "",
            "projectID": projectId,
            "qrURL": qrURL
        ]

        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            pushPayload: payload
        )
        XCTAssertFalse(isAuthenticated)

        assertError(
            current: authError,
            expected: AuthenticationError.invalidPushNotificationPayload
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

        qrURL = "https://mcl.mpin.io/mobile-login/#invalidAccessId"
        payload = [
            "userID": userId,
            "projectID": projectId,
            "qrURL": qrURL
        ]
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            pushPayload: payload
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
        qrURL = "https://mcl.mpin.io/mobile-login/#\(differentAccessId)"
        payload = [
            "userID": userId,
            "projectID": projectId,
            "qrURL": qrURL
        ]
        let (isAuthenticated, authError) = try authentication.authenticateUser(
            user: XCTUnwrap(user),
            pushPayload: payload
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
            pushPayload: payload
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
            pushPayload: payload
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
            pushPayload: payload
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
            pushPayload: payload
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
            pushPayload: payload
        )

        XCTAssertFalse(isAuthenticated)
        assertError(current: authError, expected: AuthenticationError.pinCancelled)
    }
}
