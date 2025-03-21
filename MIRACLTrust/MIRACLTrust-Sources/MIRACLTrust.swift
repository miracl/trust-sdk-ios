import Foundation

/// Main class of the SDK used for all possible actions like registration and authentication.
/// - Tag: miracltrust
@objc open class MIRACLTrust: NSObject {
    // MARK: Public properties

    @objc public var users: [User] {
        userStorage.all()
    }

    @objc public var projectId: String

    // MARK: Private properties

    var deviceName: String
    var miraclAPI: APIBlueprint
    var userStorage: UserStorage
    var crypto: CryptoBlueprint
    var urlSessionConfiguration: URLSessionConfiguration
    var sdkConfigured: Bool = false
    var miraclLogger: MIRACLLogger

    private nonisolated(unsafe) static var shared: MIRACLTrust!
    private static let sharedQueue = DispatchQueue(label: "com.miracl.trust.init.queue")

    private init(configuration: Configuration) {
        if let logger = configuration.logger {
            miraclLogger = MIRACLLogger(
                logger: logger
            )
        } else {
            miraclLogger = MIRACLLogger(logger: DefaultLogger(level: configuration.loggingLevel))
        }

        projectId = configuration.projectId
        deviceName = configuration.deviceName
        urlSessionConfiguration = configuration.urlSessionConfiguration
        userStorage =
            configuration.userStorage ??
            SQLiteUserStorage(
                projectId: configuration.projectId
            )

        miraclAPI = API(
            baseURL: configuration.platformURL,
            urlSessionConfiguration: configuration.urlSessionConfiguration,
            miraclLogger: miraclLogger
        )

        crypto = Crypto(miraclLogger: miraclLogger)
    }

    // MARK: SDK Configuration

    /// Getting singleton instance of the MIRACLTrust class.
    /// - Returns: singleton instance of the MIRACLTrust class.
    @objc public class func getInstance() -> MIRACLTrust {
        sharedQueue.sync {
            precondition(shared != nil, "MIRACLTrust SDK not initialized.Call `configure(with:)` method first.")
            precondition(shared.sdkConfigured, "MIRACLTrust SDK is not configured.Check if configuration throws error.")

            return MIRACLTrust.shared
        }
    }

    /// Configure SDK with values issued by MIRACL and stored in the [Configuration](x-source-tag://Configuration) object.
    /// It is recommended to be called right after the application is launched.
    /// - Parameter configuration:object storing configurations of the SDK.
    @objc public class func configure(with configuration: Configuration) throws {
        try sharedQueue.sync {
            shared = MIRACLTrust(configuration: configuration)
            shared.sdkConfigured = false

            let sdkVersion = Bundle(for: MIRACLTrust.self).infoDictionary?["MIRACL_SDK_VERSION"] ?? ""
            var miraclHeader = "MIRACL iOS SDK/\(sdkVersion)"
            if let applicationInfo = configuration.applicationInfo {
                miraclHeader.append(" \(applicationInfo)")
            }

            if var additionalHeaders = configuration.urlSessionConfiguration.httpAdditionalHeaders {
                additionalHeaders["X-MIRACL-CLIENT"] = miraclHeader
            } else {
                configuration.urlSessionConfiguration.httpAdditionalHeaders = ["X-MIRACL-CLIENT": miraclHeader]
            }

            shared.miraclAPI = API(
                baseURL: configuration.platformURL,
                urlSessionConfiguration: configuration.urlSessionConfiguration,
                miraclLogger: shared.miraclLogger
            )

            try shared.userStorage.loadStorage()

            // If this line is reached, configuration is done correctly.
            shared.sdkConfigured = true
        }
    }

    /// Configure a new project ID when the SDK have to work with a different project.
    /// - Parameters:
    ///   - projectId: `Project ID` setting for the MIRACL Platform that needs to be updated.
    @objc public func setProjectId(projectId: String) throws {
        if projectId.isEmpty {
            throw ConfigurationError.configurationEmptyProjectId
        }

        self.projectId = projectId
    }

    // MARK: Verification

    /// Sending email for user id verification.
    /// - Parameters:
    ///  - userId: identifier of the user identity. To verify identity this identifier needs to be valid email address.
    ///  - authenticationSessionDetails: details for an authentication session.
    ///  - completionHandler: a closure called when the verification has been completed. It can contain a verification response object or an optional error object.
    /// - Tag: miracltrust-_FUNC_sendverificationemailuseridauthenticationsessiondetailscompletionhandler
    @objc public func sendVerificationEmail(
        userId: String,
        authenticationSessionDetails: AuthenticationSessionDetails? = nil,
        completionHandler: @escaping VerificationCompletionHandler
    ) {
        do {
            let verificator = try Verificator(
                userId: userId,
                projectId: projectId,
                deviceName: deviceName,
                accessId: authenticationSessionDetails?.accessId,
                miraclAPI: miraclAPI,
                completionHandler: completionHandler
            )
            verificator.verify()
        } catch {
            logError(error: error, category: .verification)

            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// The method confirms user verification and as a result, an activation token is obtained. This activation token should be used in the registration process.
    /// - Parameters:
    ///   - verificationURL: a verification URL received as part of the verification process.
    ///   - completionHandler: a closure called when the verification has been confirmed. It can contain an optional ActivationTokenResponse object and an optional error object.
    /// - Tag:miracltrust-_FUNC_getactivationtokenverificationurlcompletionhandler
    @objc public func getActivationToken(
        verificationURL: URL,
        completionHandler: @escaping ActivationTokenCompletionHandler
    ) {
        do {
            let handler = try VerificationConfirmationHandler(
                verificationURL: verificationURL,
                miraclAPI: miraclAPI,
                completionHandler: completionHandler
            )
            handler.handle()
        } catch {
            logError(error: error, category: .verificationConfirmation)

            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// The method confirms user verification and as a result, an activation token is obtained. This activation token should be used in the registration process.
    /// - Parameters:
    ///   - userId: identifier of the user.
    ///   - code: the verification code sent to the user email.
    ///   - completionHandler: a closure called when the verification has been confirmed. It can contain an optional ActivationTokenResponse object and an optional error object.
    @objc public func getActivationToken(
        userId: String,
        code: String,
        completionHandler: @escaping ActivationTokenCompletionHandler
    ) {
        do {
            let handler = try VerificationConfirmationHandler(
                userId: userId,
                activationCode: code,
                miraclAPI: miraclAPI,
                completionHandler: completionHandler
            )
            handler.handle()
        } catch {
            logError(error: error, category: .verificationConfirmation)

            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// Generate [QuickCode](https://miracl.com/resources/docs/guides/built-in-user-verification/quickcode/) for a registered user.
    /// - Parameters:
    ///   - user: the user to generate `QuickCode` for.
    ///   - didRequestPinHandler: a closure called when the PIN code is needed from the SDK. It can be used to show UI for entering the PIN code. Its parameter is another closure that is mandatory to be called after the user finishes their action.
    ///   - completionHandler: a closure called when the `QuickCode` has been generated. It can contain a generated QuickCode object or an optional error object.
    @objc public func generateQuickCode(
        user: User,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping QuickCodeCompletionHandler
    ) {
        let generator = QuickCodeGenerator(
            user: user,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { quickCode, error in
                completionHandler(quickCode, error)
            }
        )
        generator.generate()
    }

    // MARK: User Registration

    /// Creates a new identity in the MIRACL platform.
    /// - Parameters:
    ///   - userId: an identifier of the user (e.g email address).
    ///   - activationToken: a token obtained during the user verification process indicating that the user has been already verified.
    ///   - pushNotificationsToken: current device push notifications token. This is used when push notifications for authentication
    ///   are enabled in the platform.
    ///   - didRequestPinHandler: a closure called when the PIN code is needed from the SDK. It can be used to show UI for entering the PIN code. Its parameter is another closure that is mandatory to be called after the user finishes their action.
    ///   - completionHandler: a closure called when creating a new identity has finished. It can contain an error object or the User where both of them are optional objects.
    @objc public func register(
        for userId: String,
        activationToken: String,
        pushNotificationsToken: String? = nil,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping RegistrationCompletionHandler
    ) {
        do {
            let registrator = try Registrator(
                userId: userId,
                activationToken: activationToken,
                deviceName: deviceName,
                pushNotificationsToken: pushNotificationsToken,
                api: miraclAPI,
                crypto: crypto,
                didRequestPinHandler: didRequestPinHandler,
                completionHandler: { user, error in
                    completionHandler(user, error)
                }
            )
            registrator.register()
        } catch {
            logError(error: error, category: .registration)

            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    // MARK: Authentication

    /// Authenticate identity to the MIRACL Trust platform by generating a [JWT](https://jwt.io)
    /// authentication token.
    ///
    /// Use this method to authenticate within your application.
    ///
    /// After the JWT authentication token is generated, it needs to be sent to the application
    /// server for verification. When received, the application server should verify the
    /// token signature using the MIRACL Trust [JWKS](https://api.mpin.io/.well-known/jwks)
    /// endpoint and the `audience` claim which in this case is the application project ID.
    ///
    /// - Parameters:
    ///   - user: object that keeps an authentication identity in it.
    ///   - didRequestPinHandler: a closure called when the PIN code is needed from the SDK. It can be used to show UI for entering the PIN code. Its parameter is another closure that is mandatory to be called after the user finishes their action.
    ///   - completionHandler: a closure called when the JWT is generated. It can contain an optional JWT token or an optional error object.
    @objc(authenticateWithUser:didRequestPinHandler:completionHandler:)
    public func authenticate(
        user: User,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping JWTCompletionHandler
    ) {
        let jwtGenerator = JWTGenerator(
            user: user,
            miraclAPI: miraclAPI,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { jwt, error in
                completionHandler(jwt, error)
            }
        )
        jwtGenerator.generate()
    }

    /// Authenticates identity in the MIRACL platform.
    ///
    /// Use this method to authenticate another device or application with the usage of QR Code
    /// presented on MIRACL login page.
    /// - Parameters:
    ///   - user: object that keeps an authentication identity in it.
    ///   - qrCode: a string read from the QR code.
    ///   - didRequestPinHandler: a closure called when the PIN code is needed from the SDK. It can be used to show UI for entering the PIN code. Its parameter is another closure that is mandatory to be called after the user finishes their action.
    ///   - completionHandler: a closure called when the identity is authenticated. It can contain a boolean flag representing the result of the authentication or an optional error object.
    @objc(authenticateWithUser:qrCode:didRequestPinHandler:completionHandler:)
    public func authenticateWithQRCode(
        user: User,
        qrCode: String,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping AuthenticationCompletionHandler
    ) {
        let qrAuthentication = QRAuthenticator(
            user: user,
            qrCode: qrCode,
            deviceName: deviceName,
            userStorage: userStorage,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { isAuthenticated, error in
                completionHandler(isAuthenticated, error)
            }
        )

        qrAuthentication.authenticate()
    }

    /// Authenticates identity in the MIRACL platform.
    ///
    /// Use this method when you want to authenticate another device or application with the usage of Push
    /// notifications sent by a MIRACL platform.
    /// - Parameters:
    ///   - payload: payload dictionary received from push notification.
    ///   - didRequestPinHandler: a closure called when the PIN code is needed from the SDK. It can be used to show UI for entering the PIN code. Its parameter is another closure that is mandatory to be called after the user finishes their action.
    ///   - completionHandler: a closure called when the identity is authenticated. It can contain a boolean flag representing the result of the authentication or an optional error object.
    @objc(authenticateWithPushNotificationPayload:didRequestPinHandler:completionHandler:)
    public func authenticateWithPushNotificationPayload(
        payload: [AnyHashable: Any],
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping AuthenticationCompletionHandler
    ) {
        let payloadAuthentication = PushNotificationAuthenticator(
            deviceName: deviceName,
            miraclAPI: miraclAPI,
            userStorage: userStorage,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { isAuthenticated, error in
                completionHandler(isAuthenticated, error)
            }
        )
        payloadAuthentication.authenticate(with: payload)
    }

    /// Authenticates identity in the MIRACL platform.
    ///
    /// Use this method to authenticate another device or application with the usage of
    /// Universal Link created by a MIRACL platform.
    /// - Parameters:
    ///   - user: object that keeps an authentication identity in it.
    ///   - universalLinkURL: universal link for authentication.
    ///   - didRequestPinHandler: a closure called when the PIN code is needed from the SDK. It can be used to show UI for entering the PIN code. Its parameter is another closure that is mandatory to be called after the user finishes their action.
    ///   - completionHandler: a closure called when the identity is authenticated. It can contain a boolean flag representing the result of the authentication or an optional error object.
    @objc(authenticateWithUser:universalLinkURL:didRequestPinHandler:completionHandler:)
    public func authenticateWithUniversalLinkURL(
        user: User,
        universalLinkURL: URL,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping AuthenticationCompletionHandler
    ) {
        let universalLinkAuthenticator = UniversalLinkAuthenticator(
            user: user,
            universalLinkURL: universalLinkURL,
            deviceName: deviceName,
            miraclAPI: miraclAPI,
            userStorage: userStorage,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { isAuthenticated, error in
                completionHandler(isAuthenticated, error)
            }
        )
        universalLinkAuthenticator.authenticate()
    }

    // MARK: Authentication Session management

    /// Get `authentication` session details from MIRACL's platform based on session identifier.
    ///
    /// Use this method to get session details for application that tries to authenticate
    /// against MIRACL Platform with the help of QR Code.
    ///
    /// - Parameters:
    ///   - qrCode: a string read from the QR code.
    ///   - completionHandler: a closure called when the authentication session details are fetched.It can contain a newly fetched authentication session details optional object
    ///   and an optional error object.
    @objc(getAuthenticationSessionDetailsFromQRCode:completionHandler:)
    public func getAuthenticationSessionDetailsFromQRCode(
        qrCode: String,
        completionHandler: @escaping AuthenticationSessionDetailsCompletionHandler
    ) {
        do {
            let sessionDetailFetcher = try AuthenticationSessionDetailsFetcher(
                qrCode: qrCode,
                miraclAPI: miraclAPI,
                completionHandler: completionHandler
            )
            sessionDetailFetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// Get `authentication` session details from MIRACL's platform based on session identifier.
    ///
    /// Use this method to get authentication session details for application that tries to authenticate
    /// against MIRACL Platform with the help of Universal Link URL.
    ///
    /// - Parameters:
    ///   - universalLinkURL: universal link for authentication.
    ///   - completionHandler: a closure called when the authentication session details are fetched.It can contain a newly fetched authentication session details optional object
    ///   and an optional error object.
    ///
    @objc(getAuthenticationSessionDetailsFromUniversalLinkURL:completionHandler:)
    public func getAuthenticationSessionDetailsFromUniversalLinkURL(
        universalLinkURL: URL,
        completionHandler: @escaping AuthenticationSessionDetailsCompletionHandler
    ) {
        do {
            let sessionDetailFetcher = try AuthenticationSessionDetailsFetcher(
                universalLinkURL: universalLinkURL,
                miraclAPI: miraclAPI,
                completionHandler: completionHandler
            )
            sessionDetailFetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// Get `authentication` session details from MIRACL's platform based on session identifier.
    ///
    /// Use this method to get authentication session details for application that tries to authenticate
    /// against MIRACL Platform with the help of push notifications payload
    ///
    /// - Parameters:
    ///   - pushNotificationPayload: payload dictionary received from push notification.
    ///   - completionHandler: a closure called when the authentication session details are fetched.It can contain a newly fetched authentication session details optional object
    ///   and an optional error object.
    @objc(getAuthenticationSessionDetailsFromPushNotificationPayload:completionHandler:)
    public func getAuthenticationSessionDetailsFromPushNotificationPayload(
        pushNotificationPayload: [AnyHashable: Any],
        completionHandler: @escaping AuthenticationSessionDetailsCompletionHandler
    ) {
        do {
            let sessionDetailFetcher = try AuthenticationSessionDetailsFetcher(
                pushNotificationsPayload: pushNotificationPayload,
                miraclAPI: miraclAPI,
                completionHandler: completionHandler
            )
            sessionDetailFetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// Cancel the authentication session by its `SessionDetails` object
    /// - Parameters:
    ///   - authenticationSessionDetails: details for authentication session, that is in progress.
    ///   - completionHandler: a closure called when the authentication session is aborted. It can contain a boolean flag representing the result of the abortion and an optional error object.
    @objc(abortAuthenticationSession:completionHandler:)
    public func abortAuthenticationSession(
        authenticationSessionDetails: AuthenticationSessionDetails,
        completionHandler: @escaping AuthenticationSessionAborterCompletionHandler
    ) {
        do {
            let sessionAborter = try AuthenticationSessionAborter(
                accessId: authenticationSessionDetails.accessId,
                miraclAPI: miraclAPI,
                completionHandler: completionHandler
            )
            sessionAborter.abort()
        } catch {
            DispatchQueue.main.async {
                completionHandler(false, error)
            }
        }
    }

    // MARK: Signing Session management

    /// Get `signing` session details from MIRACL's platform based on session identifier.
    ///
    /// Use this method to get signing session details for application that tries to sign against MIRACL Platform with the usage of QR Code.
    ///
    /// - Parameters:
    ///   - qrCode: a string read from the QR code.
    ///   - completionHandler: a closure called when the session details are fetched.It can contain a newly fetched `signing` session details optional object
    ///   and an optional error object.
    @objc(getSigningSessionDetailsFromQRcode:completionHandler:)
    public func getSigningSessionDetailsFromQRCode(
        qrCode: String,
        completionHandler: @escaping SigningSessionDetailsCompletionHandler
    ) {
        do {
            let fetcher = try SigningSessionDetailsFetcher(
                qrCode: qrCode,
                miraclAPI: miraclAPI,
                completionHandler: completionHandler
            )
            fetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// Get `signing` session details from MIRACL's platform based on session identifier.
    ///
    /// Use this method to get signing session details for application that tries to sign against MIRACL Platform with the usage of Universal Link URL.
    ///
    /// - Parameters:
    ///   - universalLinkURL: universal link for signing.
    ///   - completionHandler: a closure called when the session details are fetched.It can contain a newly fetched `signing` session details optional object
    ///   and an optional error object.
    ///
    @objc(getSigningSessionDetailsFromUniversalLinkURL:completionHandler:)
    public func getSigningSessionDetailsFromUniversalLinkURL(
        universalLinkURL: URL,
        completionHandler: @escaping SigningSessionDetailsCompletionHandler
    ) {
        do {
            let fetcher = try SigningSessionDetailsFetcher(
                universalLinkURL: universalLinkURL,
                miraclAPI: miraclAPI,
                completionHandler: completionHandler
            )
            fetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// Cancel the signing session by its `SigningSessionDetails` object
    /// - Parameters:
    ///   - signingSessionDetails: details for signing session, that is in progress.
    ///   - completionHandler: a closure called when the signing session is aborted. It can contain a boolean flag representing the result of the abortion and an optional error object.
    @objc(abortSigningSession:completionHandler:)
    public func abortSigningSession(
        signingSessionDetails: SigningSessionDetails,
        completionHandler: @escaping SigningSessionAborterCompletionHandler
    ) {
        do {
            let aborter = try SigningSessionAborter(
                sessionId: signingSessionDetails.sessionId,
                completionHandler: completionHandler
            )

            aborter.abort()
        } catch {
            DispatchQueue.main.async {
                completionHandler(false, error)
            }
        }
    }

    // MARK: Signing

    /// Create a cryptographic signature of a given document.
    /// - Parameters:
    ///   - message: the hash of a given document.
    ///   - user: an already registered user with signing identity.
    ///   - didRequestSigningPinHandler: a closure called when the signing identity PIN code is needed from the SDK. It can be used to show UI for entering the PIN code. Its parameter is another closure that is mandatory to be called after the user finishes their action.
    ///   - completionHandler: a closure called when the signing has completed. It can contain a newly created ``SigningResult`` object and an optional error object.
    @objc public func sign(
        message: Data,
        user: User,
        didRequestSigningPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping SigningCompletionHandler
    ) {
        do {
            let signer = try Signer(
                messageHash: message,
                user: user,
                signingSessionDetails: nil,
                didRequestSigningPinHandler: didRequestSigningPinHandler,
                completionHandler: { signature, error in
                    completionHandler(signature, error)
                }
            )
            signer.sign()
        } catch {
            logError(error: error, category: .signing)
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    @objc public func _sign(
        message: Data,
        user: User,
        signingSessionDetails: SigningSessionDetails,
        didRequestSigningPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping SigningCompletionHandler
    ) {
        do {
            let signer = try Signer(
                messageHash: message,
                user: user,
                signingSessionDetails: signingSessionDetails,
                didRequestSigningPinHandler: didRequestSigningPinHandler,
                completionHandler: { signature, error in
                    completionHandler(signature, error)
                }
            )
            signer.sign()
        } catch {
            logError(error: error, category: .signing)
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    // MARK: Getting single user

    /// Get a registered user.
    /// - Parameters:
    ///   - userId: id of the user. Can be email or any other string.
    /// - Returns: User object from the database. Returns nil if there is no such object in the storage.
    @objc public func getUser(by userId: String) -> User? {
        userStorage.getUser(by: userId, projectId: projectId)
    }

    // MARK: Identities Removal

    /// Delete a registered user.
    /// - Parameter user: object that needs to be deleted.
    @objc public func delete(user: User) throws {
        try userStorage.delete(user: user)
    }

    // MARK: Private methods

    private func logError(error: Error, category: LogCategory) {
        miraclLogger.error(
            message: "\(LoggingConstants.finishedWithError)=\(error)",
            category: category
        )
    }

    private func logConfigurationError() {
        miraclLogger.error(
            message: LoggingConstants.sdkNotConfigured,
            category: .configuration
        )
    }
}
