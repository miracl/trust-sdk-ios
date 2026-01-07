import Foundation

// MARK: Public

/// A callback used to allow the application using the MIRACLTrust iOS SDK
/// to pass the PIN to the SDK.
///
/// ## Closure Parameters
/// 1. The PIN code entered by the user, or `nil` if the operation was cancelled.
public typealias ProcessPinHandler = (String?) -> Void

/// A callback used to allow the MIRACL Trust iOS SDK to request a PIN.
///
/// The application using the MIRACL Trust iOS SDK is responsible for obtaining the PIN from the
/// user and then passing it to the ``ProcessPinHandler``.
///
/// The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
///
/// ## Closure Parameters
///
/// 1. The ``ProcessPinHandler`` closure to execute with the result.
public typealias PinRequestHandler = @MainActor @Sendable (@escaping ProcessPinHandler) -> Void

/// A completion handler executed when the
/// ``MIRACLTrust/MIRACLTrust/register(for:activationToken:pushNotificationsToken:didRequestPinHandler:completionHandler:)``
/// method returns its result.
///
/// ## Closure Parameters
/// 1. The newly created ``User`` object or `nil` if the
///   operation failed.
/// 2. An optional error describing why the operation failed. This value
///   is `nil` when the first parameter is non-`nil`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias RegistrationCompletionHandler = @MainActor @Sendable (User?, Error?) -> Void

/// A completion handler executed when any of the
/// ``MIRACLTrust/MIRACLTrust/authenticateWithQRCode(user:qrCode:didRequestPinHandler:completionHandler:)``,
/// ``MIRACLTrust/MIRACLTrust/authenticateWithPushNotificationPayload(payload:didRequestPinHandler:completionHandler:)`` or
/// ``MIRACLTrust/MIRACLTrust/authenticateWithUniversalLinkURL(user:universalLinkURL:didRequestPinHandler:completionHandler:)``
/// methods returns its result.
///
/// ## Closure Parameters
/// 1. A Boolean value indicating whether the authentication was successful
///    (true if the authentication was successful).
/// 2. An optional error describing why the operation failed. This value
///   is `nil` when the first parameter is `true`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias AuthenticationCompletionHandler = @MainActor @Sendable (Bool, Error?) -> Void

/// A completion handler executed when the
/// ``MIRACLTrust/MIRACLTrust/sign(message:user:didRequestSigningPinHandler:completionHandler:)``
/// method returns its result.
///
/// ## Closure Parameters
/// 1. The newly created ``SigningResult`` object or `nil` if the
///   operation failed.
/// 2. An optional error describing why the operation failed. This value
///   is `nil` when the first parameter is non-`nil`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
///
public typealias SigningCompletionHandler = @MainActor @Sendable (SigningResult?, Error?) -> Void

/// A completion handler executed when the operation to sign a document with ``CrossDeviceSession`` has finished.
///
/// ## Closure Parameters
/// 1. A Boolean value indicating whether the signing was successful
///    (true if the signing was successful).
/// 2. An optional error describing why the operation failed. This value
///   is `nil` when the first parameter is `true`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
///
public typealias CrossDeviceSigningCompletionHandler = @MainActor @Sendable (Bool, Error?) -> Void

/// A completion handler executed when the ``MIRACLTrust/MIRACLTrust/sendVerificationEmail(userId:authenticationSessionDetails:completionHandler:)``
/// method returns its result.
///
/// ## Closure Parameters
/// 1. The newly created ``VerificationResponse`` object or `nil` if the
///   operation failed.
/// 2. An optional error describing why the operation failed. This value
///   is `nil` when the first parameter is non-`nil`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias VerificationCompletionHandler = @MainActor @Sendable (VerificationResponse?, Error?) -> Void

/// A completion handler executed when any of the ``MIRACLTrust/MIRACLTrust/getActivationToken(verificationURL:completionHandler:)``
/// or ``MIRACLTrust/MIRACLTrust/getActivationToken(userId:code:completionHandler:)``
/// methods returns its results.
///
/// ## Closure Parameters
/// 1. The newly created ``ActivationTokenResponse`` object or `nil` if the
///   operation failed.
/// 2. An optional error describing why the operation failed. This value
///   is `nil` when the first parameter is non-`nil`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias ActivationTokenCompletionHandler = @MainActor @Sendable (ActivationTokenResponse?, Error?) -> Void

/// A completion handler executed when the ``MIRACLTrust/MIRACLTrust/generateQuickCode(user:didRequestPinHandler:completionHandler:)``
/// method returns its result.
///
/// ## Closure Parameters
/// 1. The newly created ``QuickCode`` object or `nil` if the
///   operation failed.
/// 2. An optional error describing why the operation failed. This value
///   is `nil` when the first parameter is non-`nil`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias QuickCodeCompletionHandler = @MainActor @Sendable (QuickCode?, Error?) -> Void

/// A completion handler executed when the ``MIRACLTrust/MIRACLTrust/authenticate(user:didRequestPinHandler:completionHandler:)``
/// method returns its result.
///
/// ## Closure Parameters
/// 1. The newly issued [JWT](https://datatracker.ietf.org/doc/html/rfc7519) authentication token, or `nil` if the
///   operation failed.
/// 2. An optional error describing why the operation failed. This value
///   is `nil` when the first parameter is non-`nil`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias JWTCompletionHandler = @MainActor @Sendable (String?, Error?) -> Void

/// A completion handler executed when one of the ``MIRACLTrust/MIRACLTrust/getAuthenticationSessionDetailsFromQRCode(qrCode:completionHandler:)``,
/// ``MIRACLTrust/MIRACLTrust/getAuthenticationSessionDetailsFromUniversalLinkURL(universalLinkURL:completionHandler:)``
/// or ``MIRACLTrust/MIRACLTrust/getAuthenticationSessionDetailsFromPushNotificationPayload(pushNotificationPayload:completionHandler:)``
/// methods returns its result.
///
/// ## Closure Parameters
/// 1. The newly created ``AuthenticationSessionDetails``, or `nil` if the
///   operation failed.
/// 2. An optional error describing why the operation failed. This value
///   is `nil` when the first parameter is non-`nil`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias AuthenticationSessionDetailsCompletionHandler = @MainActor @Sendable (AuthenticationSessionDetails?, Error?) -> Void

/// A completion handler executed when the
/// ``MIRACLTrust/MIRACLTrust/abortAuthenticationSession(authenticationSessionDetails:completionHandler:)``
/// method returns its result.
///
/// ## Closure Parameters
/// The closure has two positional parameters:
/// 1. A Boolean value indicating whether the session was aborted successfully
///    (true if the session terminated cleanly).
/// 2. An optional error describing why the abort operation failed. This value
///    is typically nil when the first parameter is `true`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias AuthenticationSessionAborterCompletionHandler = @MainActor @Sendable (Bool, Error?) -> Void

/// A completion handler executed when either
/// ``MIRACLTrust/MIRACLTrust/getSigningSessionDetailsFromQRCode(qrCode:completionHandler:)``
/// or
/// ``MIRACLTrust/MIRACLTrust/getSigningSessionDetailsFromUniversalLinkURL(universalLinkURL:completionHandler:)``
/// returns its result.
///
/// ## Closure Parameters
/// 1. The newly created ``SigningSessionDetails``, or `nil` if the
///   operation failed.
/// 2. An optional error describing why the operation failed. This value
///   is `nil` when `details` is non-`nil`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias SigningSessionDetailsCompletionHandler = @MainActor @Sendable (SigningSessionDetails?, Error?) -> Void

/// A completion handler executed when the
/// ``MIRACLTrust/MIRACLTrust/abortSigningSession(signingSessionDetails:completionHandler:)``
/// method returns its result.
///
///
/// ## Closure Parameters
/// 1. A Boolean value indicating whether the session was aborted successfully
///    (true if the session terminated cleanly).
/// 2. An optional error describing why the abort operation failed. This value
///    is typically `nil` when the first parameter is `true`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias SigningSessionAborterCompletionHandler = @MainActor @Sendable (Bool, Error?) -> Void

/// A completion handler executed when the operation to create a ``CrossDeviceSession`` has finished.
///
/// ## Closure Parameters
/// 1. The newly created ``CrossDeviceSession``, or `nil` if creation failed.
/// 2. An optional error describing why the ``CrossDeviceSession`` isn't created. This value
///   is typically nil when the first parameter is not `nil`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias CrossDeviceSessionCompletionHandler = @MainActor @Sendable (CrossDeviceSession?, Error?) -> Void

/// A completion handler executed when a ``CrossDeviceSession`` abort operation completes.
///
/// ## Closure Parameters
/// 1. A Boolean value indicating whether the session was aborted successfully
///    (true if the session terminated cleanly).
/// 2. An optional error describing why the abort operation failed. This value
///    is typically nil when the first parameter is `true`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked `@Sendable`, the
/// handler can also be passed safely across concurrency domains.
public typealias CrossDeviceSessionAborterCompletionHandler = @MainActor @Sendable (Bool, Error?) -> Void

/// A completion handler executed when the
/// ``MIRACLTrust/MIRACLTrust/getUser(userId:completionHandler:)``
/// method returns its result.
///
/// ## Closure Parameters
/// 1. The retrieved ``User `` object if found in the storage, `nil` if the
///   operation failed or if the ``User`` object isn't found in the storage.
/// 2. An optional error describing why the user retrieval operation failed. This value
///   is typically `nil` when the first parameter is non-`nil`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
///
public typealias GetUserCompletionHandler = @MainActor @Sendable (User?, Error?) -> Void

/// A completion handler executed when the
/// ``MIRACLTrust/MIRACLTrust/delete(user:completionHandler:)``
/// method returns its result.
///
/// ## Closure Parameters
/// 1. A Boolean value indicating whether the user was deleted successfully.
/// 2. An optional error describing why the deletion operation failed. This value
///    is typically `nil` when the first parameter is `true`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias DeleteUserCompletionHandler = @MainActor @Sendable (Bool, Error?) -> Void

/// A completion handler executed when the
/// ``MIRACLTrust/MIRACLTrust/getUsers(completionHandler:)``
/// method returns its result.
///
/// ## Closure Parameters
/// 1. An array of already registered users. It is empty when there are no registered users.
/// 2. An optional error describing why the operation failed. This value
///    is typically `nil` when the first parameter is non-`nil`.
///
/// > Note: The closure is always invoked on the main actor, making it safe to update
/// user interface elements directly. Because it is marked @Sendable, the
/// handler can also be passed safely across concurrency domains.
public typealias GetUsersCompletionHandler = @MainActor @Sendable ([User]?, Error?) -> Void

public let MIRACL_API_URL = "https://api.mpin.io"

// MARK: Private

typealias AuthenticateCompletionHandler = @MainActor @Sendable (AuthenticateResponse?, Error?) -> Void
typealias APIRequestCompletionHandler<T> = @Sendable (APICallResult, T?, Error?) -> Void

let REDACTED_STRING = "<REDACTED>"
