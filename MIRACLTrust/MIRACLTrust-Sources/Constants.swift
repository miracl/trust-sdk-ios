import Foundation

public typealias ProcessPinHandler = (String?) -> Void
public typealias PinRequestHandler = @MainActor @Sendable (@escaping ProcessPinHandler) -> Void
public typealias RegistrationCompletionHandler = @MainActor @Sendable (User?, Error?) -> Void
public typealias AuthenticationCompletionHandler = @MainActor @Sendable (Bool, Error?) -> Void
public typealias SigningCompletionHandler = @MainActor @Sendable (SigningResult?, Error?) -> Void
public typealias VerificationCompletionHandler = @MainActor @Sendable (VerificationResponse?, Error?) -> Void
public typealias ActivationTokenCompletionHandler = @MainActor @Sendable (ActivationTokenResponse?, Error?) -> Void
public typealias QuickCodeCompletionHandler = @MainActor @Sendable (QuickCode?, Error?) -> Void
public typealias JWTCompletionHandler = @MainActor @Sendable (String?, Error?) -> Void
public typealias AuthenticationSessionDetailsCompletionHandler = @MainActor @Sendable (AuthenticationSessionDetails?, Error?) -> Void
public typealias AuthenticationSessionAborterCompletionHandler = @MainActor @Sendable (Bool, Error?) -> Void
public typealias SigningSessionDetailsCompletionHandler = @MainActor @Sendable (SigningSessionDetails?, Error?) -> Void
public typealias SigningSessionAborterCompletionHandler = @MainActor @Sendable (Bool, Error?) -> Void

public let MIRACL_API_URL = URL(string: "https://api.mpin.io")!

typealias AuthenticateCompletionHandler = @MainActor @Sendable (AuthenticateResponse?, Error?) -> Void
typealias APIRequestCompletionHandler<T> = @Sendable (APICallResult, T?, Error?) -> Void
