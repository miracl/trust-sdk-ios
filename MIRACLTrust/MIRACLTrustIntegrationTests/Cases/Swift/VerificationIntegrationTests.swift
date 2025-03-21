import XCTest

@testable import MIRACLTrust

class VerificationIntegrationTests: XCTestCase {
    let platformURL = ProcessInfo.processInfo.environment["platformURL"]!
    let projectId = ProcessInfo.processInfo.environment["projectIdDV"]!
    let projectIdEVC = ProcessInfo.processInfo.environment["projectIdECV"]!
    let projectIdPV = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let clientIdPV = ProcessInfo.processInfo.environment["clientIdCUV"]!
    let clientSecretPV = ProcessInfo.processInfo.environment["clientSecretCUV"]!

    let verificationTestCase = VerificationTestCase()
    let activationTokenTestCase = GetActivationTokenTestCase()
    let registrationTestCase = RegistrationTestCase()
    let deviceName = "iOS Simulator"
    let sessionDetailsTestCase = SessionDetailsTestCase()
    let api = PlatformAPIWrapper()
    let gmailService = GmailServiceTestWrapper()

    var storage = SQLiteUserStorage(
        projectId: ProcessInfo.processInfo.environment["projectIdCUV"]!,
        databaseName: testDBName
    )

    var configuration: Configuration?

    func testVerification() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"
        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectId)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        let (verified, error) = verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNotNil(verified)
        XCTAssertNil(error)

        let verificationResult = try await gmailService.getVerificationURL(receiver: extendedMailAddress, timestamp: timestamp)
        let verificationURL = try XCTUnwrap(verificationResult)

        let queryItems = try XCTUnwrap(URLComponents(url: verificationURL, resolvingAgainstBaseURL: false)?.queryItems)

        let userIdItem = try XCTUnwrap(queryItems.filter { item in
            item.name == "user_id"
        }.first)
        XCTAssertEqual(userIdItem.value, extendedMailAddress)

        let (activationTokenResponse, activationTokenError) = try activationTokenTestCase.getActivationToken(
            verificationURL: XCTUnwrap(verificationURL)
        )

        XCTAssertNil(activationTokenError)
        XCTAssertNotNil(activationTokenResponse)
        XCTAssertEqual(activationTokenResponse?.projectId, projectId)
    }

    func testVerificationWithMpinId() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"
        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectId)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        var (verificationResponse, error) = verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNotNil(verificationResponse)
        XCTAssertNil(error)

        let verificationURLResult = try await gmailService.getVerificationURL(receiver: extendedMailAddress, timestamp: timestamp)
        let verifcationURL = try XCTUnwrap(verificationURLResult)

        let (activationTokenResponse, activationTokenError) = activationTokenTestCase.getActivationToken(
            verificationURL: verifcationURL
        )

        XCTAssertNotNil(activationTokenResponse)
        XCTAssertNil(activationTokenError)

        registrationTestCase.pinCode = String(Int32.random(in: 1000 ..< 9999))
        let (user, registrationError) = registrationTestCase.registerUser(
            userId: extendedMailAddress, activationToken: activationTokenResponse!.activationToken
        )

        XCTAssertNotNil(user)
        XCTAssertNil(registrationError)

        // Prevent verification request backoff
        sleep(5)

        (verificationResponse, error) = verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNil(error)
        XCTAssertNotNil(verificationResponse)
        XCTAssertEqual(verificationResponse!.method, EmailVerificationMethod.link)
    }

    func testBackoffError() throws {
        let mailAddress = "int@miracl.com"
        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectId)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        var (verified, error) = verificationTestCase.sendVerificationEmail(
            userId: mailAddress
        )

        XCTAssertNotNil(verified)
        XCTAssertNil(error)

        (verified, error) = verificationTestCase.sendVerificationEmail(
            userId: mailAddress
        )

        XCTAssertNil(verified)
        XCTAssertNotNil(error)
        let backoffError = try XCTUnwrap(error)
        if case let VerificationError.requestBackoff(backoff) = backoffError {
            XCTAssertNotNil(backoff)
        } else {
            XCTFail("Verification - Error isn't VerificationError.backoffError")
        }
    }

    func testInvalidUserId() throws {
        let mailAddress = ""

        configuration = try Configuration
            .Builder(projectId: projectId)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (verified, error) = verificationTestCase.sendVerificationEmail(
            userId: mailAddress
        )

        XCTAssertNil(verified)
        XCTAssertNotNil(error)
        XCTAssertTrue(error is VerificationError)
        XCTAssertEqual(error as? VerificationError, VerificationError.emptyUserId)
    }

    func testVerificationWithSessionDetails() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"
        let accessId = try XCTUnwrap(api.getAccessId(projectId: projectId))
        let qrCode = "https://mcl.mpin.io#\(accessId)"

        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectId)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (sessionDetails, sessionDetailsError) = sessionDetailsTestCase.getSessionDetails(qrCode: qrCode)
        XCTAssertNil(sessionDetailsError)
        XCTAssertNotNil(sessionDetails)

        let timestamp = Date()
        let (verified, error) = verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress,
            authenticationSessionDetails: sessionDetails
        )
        XCTAssertNotNil(verified)
        XCTAssertNil(error)

        let verificationURL = try await gmailService.getVerificationURL(receiver: extendedMailAddress, timestamp: timestamp)

        let (activationTokenResponse, activationTokenError) = try activationTokenTestCase.getActivationToken(
            verificationURL: XCTUnwrap(verificationURL)
        )

        XCTAssertNil(activationTokenError)
        let response = try XCTUnwrap(activationTokenResponse)
        XCTAssertEqual(response.accessId, accessId)
    }

    func testEmailCodeVerification() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"
        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectIdEVC)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        let (verified, error) = verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNotNil(verified)
        XCTAssertNil(error)

        let code = try await gmailService.getVerificationCode(receiver: extendedMailAddress, timestamp: timestamp)

        let (activationTokenResponse, activationTokenError) = try activationTokenTestCase.getActivationToken(
            userId: extendedMailAddress, code: XCTUnwrap(code)
        )

        XCTAssertNotNil(activationTokenResponse)
        XCTAssertNil(activationTokenError)
    }

    func testEmailCodeVerificationWithMpinId() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"
        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectIdEVC)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        var (verificationResponse, error) = verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNotNil(verificationResponse)
        XCTAssertNil(error)

        sleep(5)

        let code = try await gmailService.getVerificationCode(receiver: extendedMailAddress, timestamp: timestamp)

        let (activationTokenResponse, activationTokenError) = try activationTokenTestCase.getActivationToken(
            userId: extendedMailAddress, code: XCTUnwrap(code)
        )

        XCTAssertNotNil(activationTokenResponse)
        XCTAssertNil(activationTokenError)

        registrationTestCase.pinCode = String(Int32.random(in: 1000 ..< 9999))
        let (user, registrationError) = registrationTestCase.registerUser(
            userId: extendedMailAddress, activationToken: activationTokenResponse!.activationToken
        )

        XCTAssertNotNil(user)
        XCTAssertNil(registrationError)

        // Prevent verification request backoff
        sleep(5)

        (verificationResponse, error) = verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNil(error)
        XCTAssertNotNil(verificationResponse)
        XCTAssertEqual(verificationResponse!.method, EmailVerificationMethod.code)
    }

    func testEmailCodeVerificationWithoutMpinId() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"
        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectIdEVC)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        var (verificationResponse, error) = verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNotNil(verificationResponse)
        XCTAssertNil(error)

        let code = try await gmailService.getVerificationCode(receiver: extendedMailAddress, timestamp: timestamp)

        let (activationTokenResponse, activationTokenError) = try activationTokenTestCase.getActivationToken(
            userId: extendedMailAddress, code: XCTUnwrap(code)
        )

        XCTAssertNotNil(activationTokenResponse)
        XCTAssertNil(activationTokenError)

        registrationTestCase.pinCode = String(Int32.random(in: 1000 ..< 9999))
        let (user, registrationError) = registrationTestCase.registerUser(
            userId: extendedMailAddress, activationToken: activationTokenResponse!.activationToken
        )

        XCTAssertNotNil(user)
        XCTAssertNil(registrationError)

        try MIRACLTrust.getInstance().delete(user: user!)

        // Prevent verification request backoff
        sleep(5)

        (verificationResponse, error) = verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNil(error)
        XCTAssertNotNil(verificationResponse)
        XCTAssertEqual(verificationResponse!.method, EmailVerificationMethod.link)
    }

    func testEmailCodeVerificationWithRevokedMpinId() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"
        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectIdEVC)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        var (verificationResponse, error) = verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNotNil(verificationResponse)
        XCTAssertNil(error)

        let code = try await gmailService.getVerificationCode(receiver: extendedMailAddress, timestamp: timestamp)
        let (activationTokenResponse, activationTokenError) = try activationTokenTestCase.getActivationToken(
            userId: extendedMailAddress, code: XCTUnwrap(code)
        )

        XCTAssertNotNil(activationTokenResponse)
        XCTAssertNil(activationTokenError)

        registrationTestCase.pinCode = String(Int32.random(in: 1000 ..< 9999))
        let (regUser, registrationError) = registrationTestCase.registerUser(
            userId: extendedMailAddress, activationToken: activationTokenResponse!.activationToken
        )

        XCTAssertNotNil(regUser)
        XCTAssertNil(registrationError)

        var user = try XCTUnwrap(regUser)

        let authenticationTestCase = JWTAuthenticationTestCase()
        authenticationTestCase.pinCode = String(Int32.random(in: 1000 ..< 9999))
        var (jwt, authError) = authenticationTestCase.generateJWT(user: user)
        XCTAssertNotNil(authError)
        XCTAssertNil(jwt)

        (jwt, authError) = authenticationTestCase.generateJWT(user: user)
        XCTAssertNotNil(authError)
        XCTAssertNil(jwt)

        (jwt, authError) = authenticationTestCase.generateJWT(user: user)
        assertError(current: authError, expected: AuthenticationError.revoked)
        XCTAssertNil(jwt)

        user = try XCTUnwrap(MIRACLTrust.getInstance().getUser(by: extendedMailAddress))
        XCTAssertEqual(user.revoked, true)

        (verificationResponse, error) = verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNil(error)
        XCTAssertNotNil(verificationResponse)
        XCTAssertEqual(verificationResponse!.method, EmailVerificationMethod.code)
    }

    func testCustomVerification() throws {
        let mailAddress = "int@miracl.com"
        let accessId = try XCTUnwrap(api.getAccessId(projectId: projectId))

        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectIdPV)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()

        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let expirationInSeconds = 5
        let expirationDate = Calendar.current.date(byAdding: .second, value: expirationInSeconds, to: Date())
        let verificationURL = try XCTUnwrap(
            api.getVerificaitonURL(
                clientId: clientIdPV,
                clientSecret: clientSecretPV,
                projectId: projectIdPV,
                userId: mailAddress,
                accessId: accessId,
                expiration: expirationDate
            )
        )

        let queryItems = try XCTUnwrap(URLComponents(url: verificationURL, resolvingAgainstBaseURL: false)?.queryItems)

        let userIdItem = try XCTUnwrap(queryItems.filter { item in
            item.name == "user_id"
        }.first)
        XCTAssertEqual(userIdItem.value, mailAddress)

        let (activationTokenResponse, activationTokenError) = try activationTokenTestCase.getActivationToken(
            verificationURL: XCTUnwrap(verificationURL)
        )

        XCTAssertNotNil(activationTokenResponse)
        XCTAssertNil(activationTokenError)
        XCTAssertEqual(activationTokenResponse?.projectId, projectIdPV)
        XCTAssertEqual(activationTokenResponse?.accessId, accessId)
    }

    func testExpiredActivationCode() throws {
        let mailAddress = "int@miracl.com"
        let accessId = try XCTUnwrap(api.getAccessId(projectId: projectId))

        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectIdPV)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()

        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let expirationInSeconds = 5
        let expirationDate = Calendar.current.date(byAdding: .second, value: expirationInSeconds, to: Date())
        let verificationURL = try XCTUnwrap(
            api.getVerificaitonURL(
                clientId: clientIdPV,
                clientSecret: clientSecretPV,
                projectId: projectIdPV,
                userId: mailAddress,
                accessId: accessId,
                expiration: expirationDate
            )
        )

        sleep(UInt32(expirationInSeconds + 1))

        let (tokenResponse, tokenError) = activationTokenTestCase.getActivationToken(verificationURL: verificationURL)
        XCTAssertNil(tokenResponse)

        if let confirmationError = tokenError as? ActivationTokenError, case let ActivationTokenError.unsuccessfulVerification(activationTokenErrorResponse: response) = confirmationError {
            let unwrappedResponse = try XCTUnwrap(response)
            XCTAssertEqual(unwrappedResponse.accessId, accessId)
            XCTAssertEqual(unwrappedResponse.projectId, projectIdPV)
            XCTAssertEqual(unwrappedResponse.userId, mailAddress)
        } else {
            XCTFail("VerificationConfirmationError - not matching errors - \(String(describing: tokenError))")
        }
    }

    func testInvalidActivationCode() throws {
        let mailAddress = "int@miracl.com"
        let platformURL = try XCTUnwrap(URL(string: platformURL))

        configuration = try Configuration
            .Builder(projectId: projectIdPV)
            .userStorage(userStorage: storage)
            .platformURL(url: platformURL)
            .build()

        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let verificationURL = try XCTUnwrap(
            api.getVerificaitonURL(
                clientId: clientIdPV,
                clientSecret: clientSecretPV,
                projectId: projectIdPV,
                userId: mailAddress
            )
        )

        var verificationURLComponents = try XCTUnwrap(URLComponents(url: verificationURL, resolvingAgainstBaseURL: true))
        var updatedQueryParams = [URLQueryItem]()
        verificationURLComponents.queryItems?.forEach { item in
            if item.name == "code" {
                let updatedItem = URLQueryItem(name: "code", value: UUID().uuidString)
                updatedQueryParams.append(updatedItem)
            } else {
                updatedQueryParams.append(item)
            }
        }

        verificationURLComponents.queryItems = updatedQueryParams

        let updatedURL = try XCTUnwrap(verificationURLComponents.url)
        let (tokenResponse, tokenError) = activationTokenTestCase.getActivationToken(verificationURL: updatedURL)

        XCTAssertNil(tokenResponse)
        XCTAssertNotNil(tokenError)
    }
}
