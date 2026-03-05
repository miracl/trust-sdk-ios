@testable import MIRACLTrust
import XCTest

class VerificationIntegrationTests: XCTestCase {
    let projectURLDV = ProcessInfo.processInfo.environment["projectURLDV"]!
    let projectId = ProcessInfo.processInfo.environment["projectIdDV"]!

    let projectIdECV = ProcessInfo.processInfo.environment["projectIdECV"]!
    let projectURLECV = ProcessInfo.processInfo.environment["projectURLECV"]!

    let projectIdPV = ProcessInfo.processInfo.environment["projectIdCUV"]!
    let serviceAccountToken = ProcessInfo.processInfo.environment["serviceAccountTokenCUV"]!
    let projectURLPV = ProcessInfo.processInfo.environment["projectURLCUV"]!

    let verificationTestCase = VerificationTestCase()
    let activationTokenTestCase = GetActivationTokenTestCase()
    let registrationTestCase = RegistrationTestCase()
    let deviceName = "iOS Simulator"
    let sessionDetailsTestCase = SessionDetailsTestCase()
    let crossDeviceSessionTestCase = CrossDeviceSessionCase()
    let api = PlatformAPIWrapper()
    let gmailService = GmailServiceTestWrapper()

    var storage = SQLiteUserStorage(
        projectId: ProcessInfo.processInfo.environment["projectIdCUV"]!,
        databaseName: testDBName
    )

    var configuration: Configuration?

    func testVerificationWithoutAuthenticationSession() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"

        configuration = try Configuration
            .Builder(
                projectId: projectId,
                projectURL: projectURLDV
            ).userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        let (verified, error) = await verificationTestCase.sendVerificationEmail(
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

        let (activationTokenResponse, activationTokenError) = try await activationTokenTestCase.getActivationToken(
            verificationURL: XCTUnwrap(verificationURL)
        )

        XCTAssertNil(activationTokenError)
        XCTAssertNotNil(activationTokenResponse)
        XCTAssertEqual(activationTokenResponse?.projectId, projectId)
    }

    func testVerificationWithoutCrossDeviceSession() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"

        configuration = try Configuration
            .Builder(
                projectId: projectId,
                projectURL: projectURLDV
            ).userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        let (verified, error) = await verificationTestCase.sendVerificationEmailForCrossDeviceSession(
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

        let (activationTokenResponse, activationTokenError) = try await activationTokenTestCase.getActivationToken(
            verificationURL: XCTUnwrap(verificationURL)
        )

        XCTAssertNil(activationTokenError)
        XCTAssertNotNil(activationTokenResponse)
        XCTAssertEqual(activationTokenResponse?.projectId, projectId)
    }

    func testVerificationWithMpinId() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"

        configuration = try Configuration
            .Builder(projectId: projectId, projectURL: projectURLDV)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        var (verificationResponse, error) = await verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNotNil(verificationResponse)
        XCTAssertNil(error)

        let verificationURLResult = try await gmailService.getVerificationURL(receiver: extendedMailAddress, timestamp: timestamp)
        let verifcationURL = try XCTUnwrap(verificationURLResult)

        let (activationTokenResponse, activationTokenError) = await activationTokenTestCase.getActivationToken(
            verificationURL: verifcationURL
        )

        XCTAssertNotNil(activationTokenResponse)
        XCTAssertNil(activationTokenError)

        registrationTestCase.pinCode = String(Int32.random(in: 1000 ..< 9999))
        let (user, registrationError) = try await registrationTestCase.registerUser(
            userId: extendedMailAddress, activationToken: XCTUnwrap(activationTokenResponse?.activationToken)
        )

        XCTAssertNotNil(user)
        XCTAssertNil(registrationError)

        // Prevent verification request backoff
        sleep(5)

        (verificationResponse, error) = await verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNil(error)
        XCTAssertNotNil(verificationResponse)
        XCTAssertEqual(verificationResponse?.method, EmailVerificationMethod.link)
    }

    func testBackoffError() async throws {
        let mailAddress = "int@miracl.com"

        configuration = try Configuration
            .Builder(projectId: projectId, projectURL: projectURLDV)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        var (verified, error) = await verificationTestCase.sendVerificationEmail(
            userId: mailAddress
        )

        XCTAssertNotNil(verified)
        XCTAssertNil(error)

        (verified, error) = await verificationTestCase.sendVerificationEmail(
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

    func testInvalidUserId() async throws {
        let mailAddress = ""

        configuration = try Configuration
            .Builder(projectId: projectId, projectURL: projectURLDV)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (verified, error) = await verificationTestCase.sendVerificationEmail(
            userId: mailAddress
        )

        XCTAssertNil(verified)
        XCTAssertNotNil(error)
        XCTAssertTrue(error is VerificationError)
        XCTAssertEqual(error as? VerificationError, VerificationError.emptyUserId)
    }

    func testVerificationWithSessionDetails() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"
        let session = try XCTUnwrap(api.startSession(projectId: projectId, projectURL: projectURLDV))
        let qrCode = "https://mcl.mpin.io#\(session.accessId)"

        configuration = try Configuration
            .Builder(projectId: projectId, projectURL: projectURLDV)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let (sessionDetails, sessionDetailsError) = await sessionDetailsTestCase.getSessionDetails(qrCode: qrCode)
        XCTAssertNil(sessionDetailsError)
        XCTAssertNotNil(sessionDetails)

        let timestamp = Date()
        let (verified, error) = await verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress,
            authenticationSessionDetails: sessionDetails
        )
        XCTAssertNotNil(verified)
        XCTAssertNil(error)

        let verificationURL = try await gmailService.getVerificationURL(receiver: extendedMailAddress, timestamp: timestamp)

        let (activationTokenResponse, activationTokenError) = try await activationTokenTestCase.getActivationToken(
            verificationURL: XCTUnwrap(verificationURL)
        )

        XCTAssertNil(activationTokenError)
        let response = try XCTUnwrap(activationTokenResponse)
        XCTAssertEqual(response.accessId, session.accessId)
    }

    func testVerificationWithCrossDeviceSessionDetails() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"
        let session = try XCTUnwrap(api.startSession(projectId: projectId, projectURL: projectURLDV))
        let qrCode = "https://mcl.mpin.io#\(session.accessId)"

        configuration = try Configuration
            .Builder(projectId: projectId, projectURL: projectURLDV)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let crossDeviceSession = try await crossDeviceSessionTestCase.getCrossDeviceSessionForQRCode(qrCode: qrCode)

        let timestamp = Date()
        let (verified, error) = await verificationTestCase.sendVerificationEmailForCrossDeviceSession(
            userId: extendedMailAddress,
            crossDeviceSession: crossDeviceSession
        )
        XCTAssertNotNil(verified)
        XCTAssertNil(error)

        let verificationURL = try await gmailService.getVerificationURL(receiver: extendedMailAddress, timestamp: timestamp)

        let (activationTokenResponse, activationTokenError) = try await activationTokenTestCase.getActivationToken(
            verificationURL: XCTUnwrap(verificationURL)
        )

        XCTAssertNil(activationTokenError)
        let response = try XCTUnwrap(activationTokenResponse)
        XCTAssertEqual(response.accessId, session.accessId)
    }

    func testEmailCodeVerification() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"

        configuration = try Configuration
            .Builder(projectId: projectIdECV, projectURL: projectURLECV)
            .userStorage(userStorage: storage)
            .build()

        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        let (verified, error) = await verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNotNil(verified)
        XCTAssertNil(error)

        let code = try await gmailService.getVerificationCode(receiver: extendedMailAddress, timestamp: timestamp)

        let (activationTokenResponse, activationTokenError) = try await activationTokenTestCase.getActivationToken(
            userId: extendedMailAddress, code: XCTUnwrap(code)
        )

        XCTAssertNotNil(activationTokenResponse)
        XCTAssertNil(activationTokenError)
    }

    func testEmailCodeVerificationWithMpinId() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"

        configuration = try Configuration
            .Builder(projectId: projectIdECV, projectURL: projectURLECV)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        var (verificationResponse, error) = await verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNotNil(verificationResponse)
        XCTAssertNil(error)

        sleep(5)

        let code = try await gmailService.getVerificationCode(receiver: extendedMailAddress, timestamp: timestamp)

        let (activationTokenResponse, activationTokenError) = try await activationTokenTestCase.getActivationToken(
            userId: extendedMailAddress, code: XCTUnwrap(code)
        )

        XCTAssertNotNil(activationTokenResponse)
        XCTAssertNil(activationTokenError)

        registrationTestCase.pinCode = String(Int32.random(in: 1000 ..< 9999))
        let (user, registrationError) = try await registrationTestCase.registerUser(
            userId: extendedMailAddress, activationToken: XCTUnwrap(activationTokenResponse?.activationToken)
        )

        XCTAssertNotNil(user)
        XCTAssertNil(registrationError)

        // Prevent verification request backoff
        sleep(5)

        (verificationResponse, error) = await verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNil(error)
        XCTAssertNotNil(verificationResponse)
        XCTAssertEqual(verificationResponse?.method, EmailVerificationMethod.code)
    }

    func testEmailCodeVerificationWithoutMpinId() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"

        configuration = try Configuration
            .Builder(projectId: projectIdECV, projectURL: projectURLECV)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        var (verificationResponse, error) = await verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNotNil(verificationResponse)
        XCTAssertNil(error)

        let code = try await gmailService.getVerificationCode(receiver: extendedMailAddress, timestamp: timestamp)

        let (activationTokenResponse, activationTokenError) = try await activationTokenTestCase.getActivationToken(
            userId: extendedMailAddress, code: XCTUnwrap(code)
        )

        XCTAssertNotNil(activationTokenResponse)
        XCTAssertNil(activationTokenError)

        registrationTestCase.pinCode = String(Int32.random(in: 1000 ..< 9999))
        let (user, registrationError) = try await registrationTestCase.registerUser(
            userId: extendedMailAddress, activationToken: XCTUnwrap(activationTokenResponse?.activationToken)
        )

        XCTAssertNotNil(user)
        XCTAssertNil(registrationError)

        try MIRACLTrust.getInstance().delete(user: XCTUnwrap(user))

        // Prevent verification request backoff
        sleep(5)

        (verificationResponse, error) = await verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNil(error)
        XCTAssertNotNil(verificationResponse)
        XCTAssertEqual(verificationResponse?.method, EmailVerificationMethod.link)
    }

    func testEmailCodeVerificationWithRevokedMpinId() async throws {
        let extendedMailAddress = "int+\(UUID().uuidString)@miracl.com"

        configuration = try Configuration
            .Builder(projectId: projectIdECV, projectURL: projectURLECV)
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let timestamp = Date()
        var (verificationResponse, error) = await verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNotNil(verificationResponse)
        XCTAssertNil(error)

        let code = try await gmailService.getVerificationCode(receiver: extendedMailAddress, timestamp: timestamp)
        let (activationTokenResponse, activationTokenError) = try await activationTokenTestCase.getActivationToken(
            userId: extendedMailAddress, code: XCTUnwrap(code)
        )

        XCTAssertNotNil(activationTokenResponse)
        XCTAssertNil(activationTokenError)

        registrationTestCase.pinCode = String(Int32.random(in: 1000 ..< 9999))
        let (regUser, registrationError) = try await registrationTestCase.registerUser(
            userId: extendedMailAddress, activationToken: XCTUnwrap(activationTokenResponse?.activationToken)
        )

        XCTAssertNotNil(regUser)
        XCTAssertNil(registrationError)

        var user = try XCTUnwrap(regUser)

        let authenticationTestCase = JWTAuthenticationTestCase()
        authenticationTestCase.pinCode = String(Int32.random(in: 1000 ..< 9999))
        var (jwt, authError) = await authenticationTestCase.generateJWT(user: user)
        XCTAssertNotNil(authError)
        XCTAssertNil(jwt)

        (jwt, authError) = await authenticationTestCase.generateJWT(user: user)
        XCTAssertNotNil(authError)
        XCTAssertNil(jwt)

        (jwt, authError) = await authenticationTestCase.generateJWT(user: user)
        assertError(current: authError, expected: AuthenticationError.revoked)
        XCTAssertNil(jwt)

        user = try XCTUnwrap(MIRACLTrust.getInstance().getUser(by: extendedMailAddress))
        XCTAssertEqual(user.revoked, true)

        (verificationResponse, error) = await verificationTestCase.sendVerificationEmail(
            userId: extendedMailAddress
        )

        XCTAssertNil(error)
        XCTAssertNotNil(verificationResponse)
        XCTAssertEqual(verificationResponse?.method, EmailVerificationMethod.code)
    }

    func testCustomVerification() async throws {
        let mailAddress = "int@miracl.com"
        let session = try XCTUnwrap(api.startSession(projectId: projectId, projectURL: projectURLDV))

        configuration = try Configuration
            .Builder(projectId: projectIdPV, projectURL: projectURLPV)
            .userStorage(userStorage: storage)
            .build()

        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let expirationInSeconds = 5
        let expirationDate = Calendar.current.date(byAdding: .second, value: expirationInSeconds, to: Date())
        let verificationURL = try XCTUnwrap(
            api.getVerificaitonURL(
                serviceAccountToken: serviceAccountToken,
                projectId: projectIdPV,
                projectURL: projectURLPV,
                userId: mailAddress,
                accessId: session.accessId,
                expiration: expirationDate
            )
        )

        let queryItems = try XCTUnwrap(URLComponents(url: verificationURL, resolvingAgainstBaseURL: false)?.queryItems)

        let userIdItem = try XCTUnwrap(queryItems.filter { item in
            item.name == "user_id"
        }.first)
        XCTAssertEqual(userIdItem.value, mailAddress)

        let (activationTokenResponse, activationTokenError) = try await activationTokenTestCase.getActivationToken(
            verificationURL: XCTUnwrap(verificationURL)
        )

        XCTAssertNotNil(activationTokenResponse)
        XCTAssertNil(activationTokenError)
        XCTAssertEqual(activationTokenResponse?.projectId, projectIdPV)
        XCTAssertEqual(activationTokenResponse?.accessId, session.accessId)
    }

    func testExpiredActivationCode() async throws {
        let mailAddress = "int@miracl.com"
        let session = try XCTUnwrap(api.startSession(projectId: projectId, projectURL: projectURLDV))

        configuration = try Configuration
            .Builder(projectId: projectIdPV, projectURL: projectURLPV)
            .userStorage(userStorage: storage)
            .build()

        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let expirationInSeconds = 5
        let expirationDate = Calendar.current.date(byAdding: .second, value: expirationInSeconds, to: Date())
        let verificationURL = try XCTUnwrap(
            api.getVerificaitonURL(
                serviceAccountToken: serviceAccountToken,
                projectId: projectIdPV,
                projectURL: projectURLPV,
                userId: mailAddress,
                accessId: session.accessId,
                expiration: expirationDate
            )
        )

        sleep(UInt32(expirationInSeconds + 1))

        let (tokenResponse, tokenError) = await activationTokenTestCase.getActivationToken(verificationURL: verificationURL)
        XCTAssertNil(tokenResponse)

        if let confirmationError = tokenError as? ActivationTokenError, case let ActivationTokenError.unsuccessfulVerification(activationTokenErrorResponse: response) = confirmationError {
            let unwrappedResponse = try XCTUnwrap(response)
            XCTAssertEqual(unwrappedResponse.accessId, session.accessId)
            XCTAssertEqual(unwrappedResponse.projectId, projectIdPV)
            XCTAssertEqual(unwrappedResponse.userId, mailAddress)
        } else {
            XCTFail("VerificationConfirmationError - not matching errors - \(String(describing: tokenError))")
        }
    }

    func testInvalidActivationCode() async throws {
        let mailAddress = "int@miracl.com"

        configuration = try Configuration
            .Builder(projectId: projectIdPV, projectURL: projectURLPV)
            .userStorage(userStorage: storage)
            .build()

        try MIRACLTrust.configure(with: XCTUnwrap(configuration))

        let verificationURL = try XCTUnwrap(
            api.getVerificaitonURL(
                serviceAccountToken: serviceAccountToken,
                projectId: projectIdPV,
                projectURL: projectURLPV,
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
        let (tokenResponse, tokenError) = await activationTokenTestCase.getActivationToken(verificationURL: updatedURL)

        XCTAssertNil(tokenResponse)
        XCTAssertNotNil(tokenError)
    }
}
