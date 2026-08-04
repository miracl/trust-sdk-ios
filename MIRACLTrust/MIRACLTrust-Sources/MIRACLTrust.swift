import Foundation

/// Main class of the SDK used for all possible actions like registration and authentication.
/// - Tag: miracltrust
@objc open class MIRACLTrust: NSObject {
    // MARK: Public properties

    /// Retrieves the collection of all users from the ``UserStorage`` implementation.
    ///
    /// - Note: If the storage operation fails or throws an error, this property silently catches the exception and returns an empty array (`[]`).
    @objc public var users: [User] {
        do {
            return try userStorage.all().map {
                $0.toUser()
            }
        } catch {
            return []
        }
    }

    @objc public var projectId: String

    // MARK: Private properties

    var deviceName: String
    var miraclAPI: APIBlueprint
    var userStorage: UserStorage
    var crypto: CryptoBlueprint
    var urlSessionConfiguration: URLSessionConfiguration
    var sdkConfigured: Bool = false
    var logger: Logger
    var deviceTagManager: DeviceTagManager

    private nonisolated(unsafe) static var shared: MIRACLTrust!
    nonisolated(unsafe) static var configuration: Configuration?
    nonisolated(unsafe) static var defaultUserStorage: UserStorage?

    private static let sharedQueue = DispatchQueue(label: "com.miracl.trust.init.queue")

    private init(projectId: String, projectURL: URL, configuration: Configuration) throws {
        if let logger = configuration.logger {
            self.logger = logger
        } else {
            logger = DefaultLogger(level: configuration.loggingLevel)
        }

        self.projectId = projectId
        deviceName = configuration.deviceName
        urlSessionConfiguration = configuration.urlSessionConfiguration

        miraclAPI = API(
            baseURL: projectURL,
            urlSessionConfiguration: configuration.urlSessionConfiguration,
            logger: logger
        )

        crypto = Crypto(logger: logger)

        deviceTagManager = DeviceTagManager(logger: logger)

        let sdkVersion = Bundle(for: MIRACLTrust.self).infoDictionary?["MIRACL_SDK_VERSION"] ?? MIRACLTrustVersion.current
        var miraclHeader = "MIRACL iOS SDK/\(sdkVersion)"
        if let applicationInfo = configuration.applicationInfo {
            miraclHeader.append(" \(applicationInfo)")
        }

        var additionalHeaders = configuration.urlSessionConfiguration.httpAdditionalHeaders ?? [:]
        additionalHeaders["X-Miracl-Client"] = miraclHeader
        additionalHeaders["X-Miracl-Device-Name"] = deviceName
        additionalHeaders["X-Miracl-Device-Tag"] = deviceTagManager.deviceTag

        configuration.urlSessionConfiguration.httpAdditionalHeaders = additionalHeaders

        userStorage = try MIRACLTrust.createUserStorage(
            storageType: configuration.storageType,
            projectId: projectId
        )
    }

    // MARK: SDK Configuration

    /// Gets a singleton instance of the MIRACLTrust class.
    /// - Returns: singleton instance of the MIRACLTrust class.
    @objc public class func getInstance() -> MIRACLTrust {
        sharedQueue.sync {
            precondition(shared != nil, "MIRACLTrust SDK not initialized.Call `configure(with:)` method first.")
            return MIRACLTrust.shared
        }
    }

    /// Configures the SDK with values issued by MIRACL Trust and stored in the ``Configuration`` object.
    /// Call this method immediately after the application is launched.
    /// - Parameter configuration: an object storing configurations of the SDK.
    @objc public class func configure(with configuration: Configuration) throws {
        try sharedQueue.sync {
            precondition(configuration.projectId != nil, "MIRACLTrust SDK: Project ID is missing. Pass a valid Project ID to Configuration.Builder.")

            shared = try MIRACLTrust(
                projectId: configuration.projectId!,
                projectURL: configuration.projectURL,
                configuration: configuration
            )

            if case let StorageType.custom(storage) = configuration.storageType {
                try storage.loadStorage()
            }
        }
    }

    @_spi(MIRACLTrustAuthenticatorApi)
    public static func createInstance(
        projectId: String,
        projectURL: String
    ) throws -> MIRACLTrust {
        try sharedQueue.sync {
            precondition(!projectId.isEmpty, "MIRACLTrust SDK: Project ID cannot be empty. Pass a valid Project ID when calling createInstance().")
            precondition(URL(string: projectURL) != nil, "MIRACLTrust SDK: Project URL is invalid. Pass a valid URL when calling createInstance().")

            let projectURL = URL(string: projectURL)!

            if let configuration {
                return try MIRACLTrust(
                    projectId: projectId,
                    projectURL: projectURL,
                    configuration: configuration
                )
            } else {
                let configuration = try Configuration.Builder().build()

                return try MIRACLTrust(
                    projectId: projectId,
                    projectURL: projectURL,
                    configuration: configuration
                )
            }
        }
    }

    @_spi(MIRACLTrustAuthenticatorApi)
    public static func setDefaultConfiguration(_ configuration: Configuration) throws {
        self.configuration = configuration

        if case let StorageType.custom(storage) = configuration.storageType {
            try storage.loadStorage()
        }
    }

    /// Configures a new Project ID when the SDK has to work with a different project.
    /// - Parameters:
    ///   - projectId: `Project ID` setting for the MIRACL Trust platform that needs to be updated.
    @objc public func setProjectId(
        projectId: String
    ) throws {
        if projectId.isEmpty {
            throw ConfigurationError.emptyProjectId
        }

        self.projectId = projectId
    }

    /// Configures new project settings when the SDK has to work with a different project.
    /// - Parameters:
    ///   - projectId: The unique identifier of the MIRACL Trust project.
    ///   - projectURL: MIRACL Trust Project URL that is used for communication with the MIRACL Trust API.
    @objc public func updateProjectSettings(
        projectId: String,
        projectURL: String
    ) throws {
        if projectId.isEmpty {
            throw ConfigurationError.emptyProjectId
        }

        guard let validProjectURL = URL(string: projectURL) else {
            throw ConfigurationError.invalidProjectURL
        }

        self.projectId = projectId
        miraclAPI = API(
            baseURL: validProjectURL,
            urlSessionConfiguration: urlSessionConfiguration,
            logger: logger
        )
    }

    // MARK: Verification

    /// Sends an email for User ID verification.
    /// - Parameters:
    ///  - userId: an identifier of the user. Must be a valid email address.
    ///  - authenticationSessionDetails: details for the authentication session.
    ///  - completionHandler: a closure called when the verification has been completed. It can contain a verification response object or an optional error object.
    ///
    /// - Note: Use ``sendVerificationEmail(userId:crossDeviceSession:completionHandler:)`` instead.
    @available(*, deprecated, message: "Use ``sendVerificationEmail(userId:crossDeviceSession:completionHandler:)`` instead")
    @objc public func sendVerificationEmail(
        userId: String,
        authenticationSessionDetails: AuthenticationSessionDetails?,
        completionHandler: @escaping VerificationCompletionHandler
    ) {
        var sessionIdentifier: String?

        if let authenticationSessionDetails {
            sessionIdentifier = authenticationSessionDetails.accessId
        }

        do {
            let verificator = try Verificator(
                userId: userId,
                projectId: projectId,
                deviceName: deviceName,
                sessionIdentifier: sessionIdentifier,
                miraclAPI: miraclAPI,
                userStorage: userStorage,
                deviceTagManager: deviceTagManager,
                logger: logger,
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

    /// Default method for verifying the User ID with the MIRACL Trust platform.
    /// Currently, verification is performed by sending an email.
    ///
    /// - Parameters:
    ///   - userId: an identifier of the user. Must be a valid email address.
    ///   - crossDeviceSession: the session from which the verification is started.
    ///   - completionHandler: a closure called when the verification has been completed. It can contain a verification response object or an optional error object.
    @objc public func sendVerificationEmail(
        userId: String,
        crossDeviceSession: CrossDeviceSession,
        completionHandler: @escaping VerificationCompletionHandler
    ) {
        do {
            let verificator = try Verificator(
                userId: userId,
                projectId: projectId,
                deviceName: deviceName,
                sessionIdentifier: crossDeviceSession.sessionId,
                miraclAPI: miraclAPI,
                userStorage: userStorage,
                deviceTagManager: deviceTagManager,
                logger: logger,
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

    /// Default method for verifying the User ID with the MIRACL Trust platform.
    /// Currently, verification is performed by sending an email.
    ///
    /// - Parameters:
    ///   - userId: an identifier of the user. Must be a valid email address.
    ///   - completionHandler: a closure called when the verification has been completed. It can contain a verification response object or an optional error object.
    @objc public func sendVerificationEmail(
        userId: String,
        completionHandler: @escaping VerificationCompletionHandler
    ) {
        do {
            let verificator = try Verificator(
                userId: userId,
                projectId: projectId,
                deviceName: deviceName,
                sessionIdentifier: nil,
                miraclAPI: miraclAPI,
                userStorage: userStorage,
                deviceTagManager: deviceTagManager,
                logger: logger,
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

    /// Confirms user verification and as a result, an activation token is obtained. This activation token should be used in the registration process.
    /// - Parameters:
    ///   - verificationURL: a verification URL received as part of the verification process.
    ///   - completionHandler: a closure called when the verification has been confirmed. It can contain an optional ActivationTokenResponse object and an optional error object.
    @objc public func getActivationToken(
        verificationURL: URL,
        completionHandler: @escaping ActivationTokenCompletionHandler
    ) {
        do {
            let handler = try VerificationConfirmationHandler(
                verificationURL: verificationURL,
                miraclAPI: miraclAPI,
                deviceTagManager: deviceTagManager,
                logger: logger,
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

    /// Confirms user verification and as a result, an activation token is obtained. This activation token should be used in the registration process.
    /// - Parameters:
    ///   - userId: an identifier of the user.
    ///   - code: the verification code sent to the user's email address.
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
                deviceTagManager: deviceTagManager,
                logger: logger,
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

    /// Generates a [QuickCode](https://miracl.com/resources/docs/guides/built-in-user-verification/quickcode/) for a registered user.
    /// - Parameters:
    ///   - user: the user for whom to generate a `QuickCode`.
    ///   - didRequestPinHandler: a closure called when the SDK requests a PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user completes the action.
    ///   - completionHandler: a closure called when the `QuickCode` is generated. It can contain either a generated QuickCode object or an optional error object.
    @objc public func generateQuickCode(
        user: User,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping QuickCodeCompletionHandler
    ) {
        let generator = QuickCodeGenerator(
            user: user,
            api: miraclAPI,
            deviceName: deviceName,
            storage: userStorage,
            crypto: crypto,
            logger: logger,
            deviceTagManager: deviceTagManager,
            didRequestPinHandler: didRequestPinHandler
        ) { quickCode, error in
            completionHandler(quickCode, error)
        }
        generator.generate()
    }

    // MARK: User Registration

    /// Registers a new user for a given MIRACL Trust Project to the MIRACL Trust platform.
    /// - Parameters:
    ///   - userId: an identifier of the user.
    ///   - activationToken: a token obtained during the user verification process indicating that the user has already been verified.
    ///   - pushNotificationsToken: the current device's push notifications token. This is used when push notifications for authentication
    ///   are enabled on the platform.
    ///   - didRequestPinHandler: a closure called when the SDK requests a PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user completes the action.
    ///   - completionHandler: a closure called when a new user is created. It can contain either an error object or the user, both optional.
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
                userStorage: userStorage,
                projectId: projectId,
                crypto: crypto,
                logger: logger,
                deviceTagManager: deviceTagManager,
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

    /// Generates a signed
    /// [JWT](https://datatracker.ietf.org/doc/html/rfc7519)
    /// that serves as a proof of identity for the MIRACL Trust platform.
    ///
    /// Use this method to authenticate within your application.
    ///
    /// After the JWT authentication token is generated, it must be sent to the application
    /// server for [verification](https://miracl.com/resources/docs/guides/authentication/jwt-verification/).
    ///
    /// - Parameters:
    ///   - user: the user to be authenticated.
    ///   - didRequestPinHandler: a closure called when the SDK requests a PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user completes the action.
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
            deviceName: deviceName,
            userStorage: userStorage,
            crypto: crypto,
            logger: logger,
            deviceTagManager: deviceTagManager,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { jwt, error in
                completionHandler(jwt, error)
            }
        )
        jwtGenerator.generate()
    }

    /// Authenticates identity in the MIRACL Trust platform.
    ///
    /// Use this method to authenticate another device or application with the usage of QR Code
    /// presented on the MIRACL Trust login page.
    /// - Parameters:
    ///   - user: the user to be authenticated.
    ///   - qrCode: a string read from the QR code.
    ///   - didRequestPinHandler: a closure called when the SDK requests a PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user completes the action.
    ///   - completionHandler: a closure called when the user is authenticated. It can contain a Boolean flag representing the authentication result or an optional error object.
    ///
    /// - Note: Use ``authenticateCrossDeviceSession(crossDeviceSession:user:didRequestPinHandler:completionHandler:)``  instead.
    @objc(authenticateWithUser:qrCode:didRequestPinHandler:completionHandler:)
    @available(*, deprecated, message: "Use `authenticateCrossDeviceSession(crossDeviceSession:user:didRequestPinHandler:completionHandler:)` instead.")
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
            crypto: crypto,
            miraclAPI: miraclAPI,
            userStorage: userStorage,
            logger: logger,
            deviceTagManager: deviceTagManager,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { isAuthenticated, error in
                completionHandler(isAuthenticated, error)
            }
        )

        qrAuthentication.authenticate()
    }

    /// Authenticates the user in the MIRACL Trust platform.
    ///
    /// Use this method when you want to authenticate another device or application using push
    /// notifications sent by the MIRACL Trust platform.
    /// - Parameters:
    ///   - payload: a dictionary received from the push notification.
    ///   - didRequestPinHandler: a closure called when the SDK requests a PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user completes the action.
    ///   - completionHandler: a closure called when the user is authenticated. It can contain a Boolean flag representing the authentication result or an optional error object.
    ///
    /// - Note: Use ``authenticateCrossDeviceSession(crossDeviceSession:user:didRequestPinHandler:completionHandler:)`` instead.
    @objc(authenticateWithPushNotificationPayload:didRequestPinHandler:completionHandler:)
    @available(*, deprecated, message: "Use `authenticateCrossDeviceSession(crossDeviceSession:user:didRequestPinHandler:completionHandler:))` instead.")
    public func authenticateWithPushNotificationPayload(
        payload: [AnyHashable: Any],
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping AuthenticationCompletionHandler
    ) {
        let payloadAuthentication = PushNotificationAuthenticator(
            deviceName: deviceName,
            miraclAPI: miraclAPI,
            userStorage: userStorage,
            crypto: crypto,
            logger: logger,
            deviceTagManager: deviceTagManager,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { isAuthenticated, error in
                completionHandler(isAuthenticated, error)
            }
        )
        payloadAuthentication.authenticate(with: payload)
    }

    /// Authenticates the user in the MIRACL Trust platform.
    ///
    /// Use this method to authenticate another device or application using a
    /// Universal Link created by the MIRACL Trust platform.
    /// - Parameters:
    ///   - user: the user to be authenticated.
    ///   - universalLinkURL: universal link for authentication.
    ///   - didRequestPinHandler: a closure called when the SDK requests a PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user completes the action.
    ///   - completionHandler: a closure called when the user is authenticated. It can contain a Boolean flag representing the authentication result or an optional error object.
    ///
    /// - Note: Use ``authenticateCrossDeviceSession(crossDeviceSession:user:didRequestPinHandler:completionHandler:)`` instead.
    @objc(authenticateWithUser:universalLinkURL:didRequestPinHandler:completionHandler:)
    @available(*, deprecated, message: "Use `authenticateCrossDeviceSession(crossDeviceSession:user:didRequestPinHandler:completionHandler:)` instead.")
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
            crypto: crypto,
            userStorage: userStorage,
            logger: logger,
            deviceTagManager: deviceTagManager,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { isAuthenticated, error in
                completionHandler(isAuthenticated, error)
            }
        )
        universalLinkAuthenticator.authenticate()
    }

    // MARK: Cross Device Session

    /// Gets ``CrossDeviceSession`` for a QR code.
    ///
    /// - Parameters:
    ///   - qrCode: a string read from the QR code.
    ///   - completionHandler: a closure called when the ``CrossDeviceSession`` is fetched. It can contain a ``CrossDeviceSession`` optional object
    ///   and an optional error object.
    @objc(getCrossDeviceSessionFromQRCode:completionHandler:)
    public func getCrossDeviceSessionFromQRCode(
        qrCode: String,
        completionHandler: @escaping CrossDeviceSessionCompletionHandler
    ) {
        do {
            let fetcher = try CrossDeviceSessionFetcher(
                qrCode: qrCode,
                miraclAPI: miraclAPI,
                logger: logger
            ) { session, error in
                completionHandler(session, error)
            }

            fetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// Gets ``CrossDeviceSession`` for a universal link.
    ///
    /// - Parameters:
    ///   - universalLinkURL: universal link for authentication.
    ///   - completionHandler: a closure called when the ``CrossDeviceSession`` is fetched. It can contain a ``CrossDeviceSession`` optional object
    ///   and an optional error object.
    @objc(getCrossDeviceSessionFromUniversalLinkURL:completionHandler:)
    public func getCrossDeviceSessionFromUniversalLinkURL(
        universalLinkURL: URL,
        completionHandler: @escaping CrossDeviceSessionCompletionHandler
    ) {
        do {
            let fetcher = try CrossDeviceSessionFetcher(
                universalLinkURL: universalLinkURL,
                miraclAPI: miraclAPI,
                logger: logger
            ) { session, error in
                completionHandler(session, error)
            }

            fetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// Gets ``CrossDeviceSession`` for a push notification.
    ///
    /// - Parameters:
    ///   - pushNotificationPayload: a dictionary received from the push notification.
    ///   - completionHandler: a closure called when the ``CrossDeviceSession`` is fetched. It can contain a ``CrossDeviceSession`` optional object
    ///   and an optional error object.
    @objc(getCrossDeviceSessionFromPushNotificationPayload:completionHandler:)
    public func getCrossDeviceSessionFromPushNotificationPayload(
        pushNotificationPayload: [AnyHashable: Any],
        completionHandler: @escaping CrossDeviceSessionCompletionHandler
    ) {
        do {
            let fetcher = try CrossDeviceSessionFetcher(
                pushNotificationPayload: pushNotificationPayload,
                miraclAPI: miraclAPI,
                logger: logger
            ) { session, error in
                completionHandler(session, error)
            }

            fetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// Authenticates the user in the MIRACL Trust platform.
    ///
    /// Use this method to authenticate another device or application using ``CrossDeviceSession``.
    ///
    /// - Parameters:
    ///   - crossDeviceSession: details for the authentication operation.
    ///   - user: the user to be authenticated.
    ///   - didRequestPinHandler: a closure called when the SDK requests a PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user completes the action.
    ///   - completionHandler: a closure called when the user is authenticated. It can contain a Boolean flag representing the authentication result or an optional error object.
    @objc(authenticateCrossDeviceSession:user:didRequestPinHandler:completionHandler:)
    public func authenticateCrossDeviceSession(
        crossDeviceSession: CrossDeviceSession,
        user: User,
        didRequestPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping AuthenticationCompletionHandler
    ) {
        let crossDeviceSessionAuthenticator = CrossDeviceSessionAuthenticator(
            user: user,
            crossDeviceSession: crossDeviceSession,
            miraclAPI: miraclAPI,
            userStorage: userStorage,
            crypto: crypto,
            deviceName: deviceName,
            logger: logger,
            deviceTagManager: deviceTagManager,
            didRequestPinHandler: didRequestPinHandler,
            completionHandler: { isAuthenticated, error in
                if let error, case AuthenticationError.invalidAuthenticationSession = error {
                    completionHandler(isAuthenticated, AuthenticationError.invalidCrossDeviceSession)
                } else {
                    completionHandler(isAuthenticated, error)
                }
            }
        )

        crossDeviceSessionAuthenticator.authenticate()
    }

    /// Generates a signature for a hash provided by the ``CrossDeviceSession`` parameter and updates the session.
    ///
    /// - Parameters:
    ///   - crossDeviceSession: details for the signing operation.
    ///   - user: a registered user with a signing User ID.
    ///   - didRequestSigningPinHandler: a closure called when the SDK requests the signing User ID's PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user finishes their action.
    ///   - completionHandler: a closure called when the signing has completed. It can contain a Boolean flag and an optional error object.
    @objc(signCrossDeviceSession:user:didRequestSigningPinHandler:completionHandler:)
    public func signCrossDeviceSession(
        crossDeviceSession: CrossDeviceSession,
        user: User,
        didRequestSigningPinHandler: @escaping PinRequestHandler,
        completionHandler: @escaping CrossDeviceSigningCompletionHandler
    ) {
        do {
            let signer = try Signer(
                messageHash: Data(hexString: crossDeviceSession.signingHash),
                sessionIdentifier: crossDeviceSession.sessionId,
                user: user,
                miraclAPI: miraclAPI,
                userStorage: userStorage,
                crypto: crypto,
                logger: logger,
                deviceName: deviceName,
                deviceTagManager: deviceTagManager,
                didRequestSigningPinHandler: didRequestSigningPinHandler
            ) { signinResult, error in
                if signinResult != nil {
                    completionHandler(true, nil)
                } else if let error {
                    completionHandler(false, error)
                } else {
                    completionHandler(false, SigningError.signingFail(nil))
                }
            }
            signer.sign()
        } catch {
            logError(error: error, category: .signing)
            DispatchQueue.main.async {
                completionHandler(false, error)
            }
        }
    }

    /// Cancels the ``CrossDeviceSession``.
    ///
    /// - Parameters:
    ///   - crossDeviceSession: the session to be cancelled.
    ///   - completionHandler: a closure called when the ``CrossDeviceSession`` is aborted. It can contain a Boolean flag representing the abortion result and an optional error object.
    @objc(abortCrossDeviceSession:completionHandler:)
    public func abortCrossDeviceSession(
        crossDeviceSession: CrossDeviceSession,
        completionHandler: @escaping CrossDeviceSessionAborterCompletionHandler
    ) {
        do {
            let aborter = try CrossDeviceSessionAborter(
                sessionId: crossDeviceSession.sessionId,
                miraclAPI: miraclAPI
            ) { result, error in
                completionHandler(result, error)
            }

            aborter.abort()
        } catch {
            DispatchQueue.main.async {
                completionHandler(false, error)
            }
        }
    }

    // MARK: Authentication Session management

    /// Gets `authentication` session details from the MIRACL Trust platform based on the session identifier.
    ///
    /// Use this method to retrieve authentication session details for an application that tries to authenticate
    /// with the MIRACL Trust platform using a QR Code.
    ///
    /// - Parameters:
    ///   - qrCode: a string read from the QR code.
    ///   - completionHandler: a closure called when the authentication session details are fetched. It can contain a newly fetched authentication session details optional object
    ///   and an optional error object.
    ///
    /// - Note: Use ``getCrossDeviceSessionFromQRCode(qrCode:completionHandler:)`` instead.
    @objc(getAuthenticationSessionDetailsFromQRCode:completionHandler:)
    @available(*, deprecated, message: "Use `getCrossDeviceSessionFromQRCode(qrCode:completionHandler:)` instead", renamed: "getCrossDeviceSessionFromQRCode(qrCode:completionHandler:)")
    public func getAuthenticationSessionDetailsFromQRCode(
        qrCode: String,
        completionHandler: @escaping AuthenticationSessionDetailsCompletionHandler
    ) {
        do {
            let sessionDetailFetcher = try AuthenticationSessionDetailsFetcher(
                qrCode: qrCode,
                miraclAPI: miraclAPI,
                logger: logger,
                completionHandler: completionHandler
            )
            sessionDetailFetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// Gets `authentication` session details from the MIRACL Trust platform based on the session identifier.
    ///
    /// Use this method to retrieve authentication session details for an application that tries to authenticate
    /// with the MIRACL Trust platform using a Universal Link URL.
    ///
    /// - Parameters:
    ///   - universalLinkURL: a universal link for authentication.
    ///   - completionHandler: a closure called when the authentication session details are fetched. It can contain a newly fetched authentication session details optional object
    ///   and an optional error object.
    ///
    ///  - Note: Use ``getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL:completionHandler:)`` instead.
    @objc(getAuthenticationSessionDetailsFromUniversalLinkURL:completionHandler:)
    @available(*, deprecated, message: "Use `getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL:completionHandler:)` instead", renamed: "getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL:completionHandler:)")
    public func getAuthenticationSessionDetailsFromUniversalLinkURL(
        universalLinkURL: URL,
        completionHandler: @escaping AuthenticationSessionDetailsCompletionHandler
    ) {
        do {
            let sessionDetailFetcher = try AuthenticationSessionDetailsFetcher(
                universalLinkURL: universalLinkURL,
                miraclAPI: miraclAPI,
                logger: logger,
                completionHandler: completionHandler
            )
            sessionDetailFetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// Gets `authentication` session details from the MIRACL Trust platform based on the session identifier.
    ///
    /// Use this method to retrieve authentication session details for an application that tries to authenticate
    /// with the MIRACL Trust platform using a push notifications payload.
    ///
    /// - Parameters:
    ///   - pushNotificationPayload: a dictionary received from the push notification.
    ///   - completionHandler: a closure called when the authentication session details are fetched. It can contain a newly fetched authentication session details optional object
    ///   and an optional error object.
    ///
    /// - Note: Use ``getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload:completionHandler:)`` instead.
    @objc(getAuthenticationSessionDetailsFromPushNotificationPayload:completionHandler:)
    @available(*, deprecated, message: "Use getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload:completionHandler:) instead.", renamed: "getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload:completionHandler:)")
    public func getAuthenticationSessionDetailsFromPushNotificationPayload(
        pushNotificationPayload: [AnyHashable: Any],
        completionHandler: @escaping AuthenticationSessionDetailsCompletionHandler
    ) {
        do {
            let sessionDetailFetcher = try AuthenticationSessionDetailsFetcher(
                pushNotificationsPayload: pushNotificationPayload,
                miraclAPI: miraclAPI,
                logger: logger,
                completionHandler: completionHandler
            )
            sessionDetailFetcher.fetch()
        } catch {
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    /// Cancels the authentication session by its `SessionDetails` object.
    ///
    /// - Parameters:
    ///   - authenticationSessionDetails: details for the authentication session that is in progress.
    ///   - completionHandler: a closure called when the authentication session is aborted. It can contain a Boolean flag representing the abortion result and an optional error object.
    ///   - Note: Use ``abortCrossDeviceSession(_:completionHandler:)`` instead.
    @objc(abortAuthenticationSession:completionHandler:)
    @available(*, deprecated, message: "Use `abortCrossDeviceSession(_:completionHandler:)` instead.")
    public func abortAuthenticationSession(
        authenticationSessionDetails: AuthenticationSessionDetails,
        completionHandler: @escaping AuthenticationSessionAborterCompletionHandler
    ) {
        do {
            let sessionAborter = try AuthenticationSessionAborter(
                accessId: authenticationSessionDetails.accessId,
                miraclAPI: miraclAPI,
                logger: logger,
                completionHandler: completionHandler
            )
            sessionAborter.abort()
        } catch {
            DispatchQueue.main.async {
                completionHandler(false, error)
            }
        }
    }

    // MARK: Signing

    /// Creates a cryptographic signature of a given document.
    ///
    /// - Parameters:
    ///   - message: the hash of a given document.
    ///   - user: a registered user with a signing User ID.
    ///   - didRequestSigningPinHandler: a closure called when the SDK requests a signing User ID's PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user finishes their action.
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
                sessionIdentifier: nil,
                user: user,
                miraclAPI: miraclAPI,
                userStorage: userStorage,
                crypto: crypto,
                logger: logger,
                deviceName: deviceName,
                deviceTagManager: deviceTagManager,
                didRequestSigningPinHandler: didRequestSigningPinHandler
            ) { signature, error in
                completionHandler(signature, error)
            }

            signer.sign()
        } catch {
            logError(error: error, category: .signing)
            DispatchQueue.main.async {
                completionHandler(nil, error)
            }
        }
    }

    // MARK: Getting single user

    /// Retrieves a registered user synchronously.
    ///
    /// - Parameters:
    ///   - userId: an identifier of the user.
    /// - Returns: The the ``User`` object if found; otherwise, `nil` (for example, if the user does not exist or a storage error occurs).
    @objc public func getUser(by userId: String) -> User? {
        try? userStorage.getUser(by: userId, projectId: projectId)?.toUser()
    }

    /// Retrieves a registered user asynchronously.
    ///
    /// - Parameters:
    ///   - userId: an identifier of the user.
    ///   - completionHandler: The ``GetUserCompletionHandler`` closure to be executed when the request completes.
    @objc public func getUser(
        userId: String,
        completionHandler: @escaping GetUserCompletionHandler
    ) {
        let storage = userStorage
        let projectId = projectId

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let user = try storage.getUser(by: userId, projectId: projectId)
                DispatchQueue.main.async {
                    completionHandler(user?.toUser(), nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        }
    }

    // MARK: Getting all registered users

    /// Retrieves a list of all registered users asynchronously.
    ///
    /// - Parameter completionHandler: The ``GetUsersCompletionHandler`` closure to be executed when the request completes.
    @objc public func getUsers(completionHandler: @escaping GetUsersCompletionHandler) {
        let storage = userStorage
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let allUsers = try storage.all().map { userDTO in
                    userDTO.toUser()
                }

                DispatchQueue.main.async {
                    completionHandler(allUsers, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        }
    }

    @_spi(MIRACLTrustAuthenticatorApi)
    public static func getUsers() -> [User] {
        MIRACLTrust.sharedQueue.sync {
            var userStorage: UserStorage?

            if let configuration, case let StorageType.custom(customUserStorage) = configuration.storageType {
                userStorage = customUserStorage
            } else if let defaultUserStorage = MIRACLTrust.defaultUserStorage {
                userStorage = defaultUserStorage
            } else if let configuration, case let StorageType.default(options) = configuration.storageType {
                userStorage = SQLiteUserStorage(
                    projectId: "",
                    directoryURL: options.directoryURL,
                    databaseName: options.storageName,
                    keychainAccessGroup: options.keychainAccessGroup
                )
                MIRACLTrust.defaultUserStorage = userStorage
                try? userStorage?.loadStorage()
            } else {
                userStorage = SQLiteUserStorage(
                    projectId: ""
                )
                MIRACLTrust.defaultUserStorage = userStorage
                try? userStorage?.loadStorage()
            }

            if let userStorage {
                do {
                    return try userStorage.all().map { $0.toUser() }
                } catch {
                    return []
                }
            }

            return []
        }
    }

    // MARK: Identities Removal

    /// Deletes a registered user synchronously.
    ///
    /// - Parameter user: The ``User`` object to be deleted.
    @objc public func delete(user: User) throws {
        try userStorage.delete(user: user.toUserDTO())
    }

    /// Deletes a registered user asynchronously.
    ///
    /// - Parameters:
    ///   - user: The ``User`` object to be deleted.
    ///   - completionHandler: The ``DeleteUserCompletionHandler`` closure to be executed when the request completes.
    @objc public func delete(
        user: User,
        completionHandler: @escaping DeleteUserCompletionHandler
    ) {
        let storage = userStorage
        let completionHandler = completionHandler

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try storage.delete(user: user.toUserDTO())

                DispatchQueue.main.async {
                    completionHandler(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completionHandler(false, error)
                }
            }
        }
    }

    // MARK: Private methods

    private func logError(error: Error, category: LogCategory) {
        logger.error(
            message: "\(LoggingConstants.finishedWithError)=\(error)",
            category: category
        )
    }

    private func logConfigurationError() {
        logger.error(
            message: LoggingConstants.sdkNotConfigured,
            category: .configuration
        )
    }

    private class func createUserStorage(
        storageType: StorageType,
        projectId: String
    ) throws -> UserStorage {
        dispatchPrecondition(condition: .onQueue(sharedQueue))

        var userStorage: UserStorage
        switch storageType {
        case let .default(options):
            if let defaultUserStorage = MIRACLTrust.defaultUserStorage {
                userStorage = defaultUserStorage
            } else {
                userStorage = SQLiteUserStorage(
                    projectId: projectId,
                    directoryURL: options.directoryURL,
                    databaseName: options.storageName,
                    keychainAccessGroup: options.keychainAccessGroup
                )
                try userStorage.loadStorage()
                MIRACLTrust.defaultUserStorage = userStorage
            }
        case let .custom(storage):
            userStorage = storage
        }

        return userStorage
    }
}
