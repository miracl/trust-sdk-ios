import Foundation

public extension MIRACLTrust {
    /// Default method for verifying the User ID with the MIRACL Trust platform.
    ///
    /// Currently, verification is performed by sending an email.
    ///
    /// - Parameters:
    ///   - userId: an identifier of the user. Must be a valid email address.
    ///   - crossDeviceSession: the session from which the verification is started.
    ///
    /// - Returns: a ``VerificationResponse`` object.
    func sendVerificationEmail(
        userId: String,
        crossDeviceSession: CrossDeviceSession
    ) async throws -> VerificationResponse {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.sendVerificationEmailCore(userId: userId, crossDeviceSession: crossDeviceSession) { response, error in
                if let response {
                    continuation.resume(returning: response)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    /// Default method for verifying the User ID with the MIRACL Trust platform.
    ///
    /// Currently, verification is performed by sending an email.
    ///
    /// - Parameter userId: an identifier of the user. Must be a valid email address.
    ///
    /// - Returns: a ``VerificationResponse`` object.
    func sendVerificationEmail(userId: String) async throws -> VerificationResponse {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.sendVerificationEmailCore(userId: userId) { response, error in
                if let response {
                    continuation.resume(returning: response)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    /// Confirms user verification and as a result, an activation token is obtained. This activation token should be used in the registration process.
    ///
    /// - Parameter verificationURL:  a verification URL received as part of the verification process.
    /// - Returns: an ``ActivationTokenResponse``  object.
    func getActivationToken(verificationURL: URL) async throws -> ActivationTokenResponse {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.getActivationTokenCore(verificationURL: verificationURL) { response, error in
                if let response {
                    continuation.resume(returning: response)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    /// Confirms user verification and as a result, an activation token is obtained. This activation token should be used in the registration process.
    /// - Parameters:
    ///   - userId: an identifier of the user.
    ///   - code: the verification code sent to the user's email address.
    /// - Returns: an ``ActivationTokenResponse``  object.
    func getActivationToken(
        userId: String,
        code: String
    ) async throws -> ActivationTokenResponse {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.getActivationTokenCore(userId: userId, code: code) { response, error in
                if let response {
                    continuation.resume(returning: response)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    /// Generates a [QuickCode](https://miracl.com/resources/docs/guides/built-in-user-verification/quickcode/) for a registered user.
    /// - Parameters:
    ///   - user:  the user for whom to generate a ``QuickCode``.
    ///   - didRequestPinHandler:  a closure called when the SDK requests a PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user completes the action.
    /// - Returns: a  ``QuickCode`` object.
    func generateQuickCode(
        user: User,
        didRequestPinHandler: @escaping PinRequestHandler
    ) async throws -> QuickCode {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.generateQuickCodeCore(user: user, didRequestPinHandler: didRequestPinHandler) { quickCode, error in
                if let quickCode {
                    continuation.resume(returning: quickCode)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    /// Registers a new user for a given MIRACL Trust Project to the MIRACL Trust platform.
    /// - Parameters:
    ///   - userId: an identifier of the user.
    ///   - activationToken: a token obtained during the user verification process indicating that the user has already been verified.
    ///   - pushNotificationsToken: the current device's push notifications token. This is used when push notifications for authentication
    ///   are enabled on the platform.
    ///   - didRequestPinHandler: a closure called when the SDK requests a PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user completes the action.
    /// - Returns: a ``User`` object.
    func register(
        userId: String,
        activationToken: String,
        pushNotificationsToken: String? = nil,
        didRequestPinHandler: @escaping PinRequestHandler
    ) async throws -> User {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.registerCore(
                for: userId,
                activationToken: activationToken,
                pushNotificationsToken: pushNotificationsToken,
                didRequestPinHandler: didRequestPinHandler
            ) { user, error in
                if let user {
                    continuation.resume(returning: user)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

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
    ///
    /// - Returns: a generated JWT token.
    func authenticate(
        user: User,
        didRequestPinHandler: @escaping PinRequestHandler
    ) async throws -> String {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.authenticateCore(user: user, didRequestPinHandler: didRequestPinHandler) { jwt, error in
                if let jwt {
                    continuation.resume(returning: jwt)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    /// Gets ``CrossDeviceSession`` for a QR code.
    /// - Parameter qrCode: a string read from the QR code.
    /// - Returns: fetched ``CrossDeviceSession``
    func getCrossDeviceSessionFromQRCode(
        qrCode: String
    ) async throws -> CrossDeviceSession {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.getCrossDeviceSessionFromQRCodeCore(qrCode: qrCode) { crossDeviceSession, error in
                if let crossDeviceSession {
                    continuation.resume(returning: crossDeviceSession)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    /// Gets ``CrossDeviceSession`` for a universal link.
    /// - Parameter universalLinkURL: universal link ?...
    /// - Returns: fetched ``CrossDeviceSession``
    func getCrossDeviceSessionFromUniversalLinkURL(
        universalLinkURL: URL
    ) async throws -> CrossDeviceSession {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.getCrossDeviceSessionFromUniversalLinkURLCore(universalLinkURL: universalLinkURL) { crossDeviceSession, error in
                if let crossDeviceSession {
                    continuation.resume(returning: crossDeviceSession)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    /// Gets ``CrossDeviceSession`` for a push notification.
    ///
    /// - Parameter pushNotificationPayload: a dictionary received from the push notification.
    ///
    /// - Returns: fetched ``CrossDeviceSession``
    func getCrossDeviceSessionFromPushNotificationPayload(
        pushNotificationPayload: [AnyHashable: Any]
    ) async throws -> CrossDeviceSession {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.getCrossDeviceSessionFromPushNotificationPayloadCore(
                pushNotificationPayload: pushNotificationPayload
            ) { crossDeviceSession, error in
                if let crossDeviceSession {
                    continuation.resume(returning: crossDeviceSession)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
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
    func authenticateCrossDeviceSession(
        crossDeviceSession: CrossDeviceSession,
        user: User,
        didRequestPinHandler: @escaping PinRequestHandler
    ) async throws {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.authenticateCrossDeviceSessionCore(
                crossDeviceSession: crossDeviceSession,
                user: user,
                didRequestPinHandler: didRequestPinHandler
            ) { isAuthenticated, error in
                if isAuthenticated {
                    continuation.resume(returning: ())
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    /// Generates a signature for a hash provided by the ``CrossDeviceSession`` parameter and updates the session.
    ///
    /// - Parameters:
    ///   - crossDeviceSession: details for the signing operation.
    ///   - user: a registered user with a signing User ID.
    ///   - didRequestSigningPinHandler: a closure called when the SDK requests the signing User ID's PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user finishes their action.
    func signCrossDeviceSession(
        crossDeviceSession: CrossDeviceSession,
        user: User,
        didRequestSigningPinHandler: @escaping PinRequestHandler
    ) async throws {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.signCrossDeviceSessionCore(
                crossDeviceSession: crossDeviceSession,
                user: user,
                didRequestSigningPinHandler: didRequestSigningPinHandler
            ) { isSigned, error in
                if isSigned {
                    continuation.resume(returning: ())
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    /// Cancels the ``CrossDeviceSession``.
    ///
    /// - Parameter crossDeviceSession: the session to be cancelled.
    func abortCrossDeviceSession(crossDeviceSession: CrossDeviceSession) async throws {
        try Task.checkCancellation()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.abortCrossDeviceSessionCore(crossDeviceSession: crossDeviceSession) { isAborted, error in
                if isAborted {
                    continuation.resume(returning: ())
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    /// Creates a cryptographic signature of a given document.
    /// - Parameters:
    ///   - message: the hash of a given document.
    ///   - user: a registered user with a signing User ID.
    ///   - didRequestSigningPinHandler: a closure called when the SDK requests a signing User ID's PIN code. It can be used to display the UI for entering the PIN code. Its parameter is another closure that must be called after the user finishes their action.
    ///
    /// - Returns: a newly created ``SigningResult`` object
    func sign(
        message: Data,
        user: User,
        didRequestSigningPinHandler: @escaping PinRequestHandler
    ) async throws -> SigningResult {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.signCore(message: message, user: user, didRequestSigningPinHandler: didRequestSigningPinHandler) { signingResult, error in
                if let signingResult {
                    continuation.resume(returning: signingResult)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    /// Retrieves a list of all registered users asynchronously.
    ///
    /// - Returns: list of all registered users.
    func getUsers() async throws -> [User] {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.getUsersCore { users, error in
                if let users {
                    continuation.resume(returning: users)
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }

    func getUser(userId: String) async throws -> User? {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { continuation in
            self.getUserCore(userId: userId) { user, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: user)
                }
            }
        }
    }

    /// Deletes a registered user asynchronously.
    ///
    /// - Parameter user: The ``User`` object to be deleted.
    func delete(user: User) async throws {
        try Task.checkCancellation()

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.deleteCore(user: user) { isDeleted, error in
                if isDeleted {
                    continuation.resume(returning: ())
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    fatalError("\(#function) fatal error")
                }
            }
        }
    }
}
