@testable import MIRACLTrust

class AuthenticationResponseManager: @unchecked Sendable {
    var authenticateError: Error?
    var authenticateResponse: AuthenticateResponse?
    var authenticateResultCall: APICallResult = .failed
    var authenticateDVSAuth = false

    func updateState() {
        if authenticateDVSAuth {
            authenticateResponse?.renewSecretResponse = nil
            authenticateDVSAuth.toggle()
        }
    }
}

struct MockAPI: APIBlueprint {
    var registerUserError: Error?
    var registrationResponse: RegistrationResponse?
    var registrationResultCall: APICallResult = .failed

    var signatureError: Error?
    var signatureResponse: SignatureResponse?
    var signatureResultCall: APICallResult = .failed

    var clientSecretError: Error?
    var clientSecretResponse: ClientSecretResponse?
    var clientSecretResultCall: APICallResult = .failed

    var pass1Error: Error?
    var pass1Response: Pass1Response?
    var pass1ResultCall: APICallResult = .failed

    var pass2Error: Error?
    var pass2Response: Pass2Response?
    var pass2ResultCall: APICallResult = .failed

    var authenticationResponseManager = AuthenticationResponseManager()

    var signingClientSecret1Error: Error?
    var signingClientSecret1Response: SigningClientSecret1Response?
    var signingClientSecret1ResultCall: APICallResult = .failed

    var verificationError: Error?
    var verificationResponse: VerificationRequestResponse?
    var verificationResultCall: APICallResult = .failed

    var verificationConfirmationError: Error?
    var verificationConfirmationResponse: VerificationConfirmationResponse?
    var verificationConfirmationResultCall: APICallResult = .failed

    var sessionDetailsError: Error?
    var sessionDetailsResponse: AuthenticationSessionsDetailsResponse?
    var sessionDetailsResultCall: APICallResult = .failed

    var sessionAborterError: Error?
    var sessionAborterResponse = [String: String]()
    var sessionAborterResultCall: APICallResult = .failed

    var signingSessionDetailsError: Error?
    var signingSessionDetailsResponse: SigningSessionDetailsResponse?
    var signingSessionDetailsResultCall: APICallResult = .failed

    var signingSessionCompleterError: Error?
    var signingSessionCompleterResponse: SigningSessionCompleterResponse?
    var signingSessionCompleterResultCall: APICallResult = .failed

    var signingSessionAborterError: Error?
    var signingSessionAborterResponse: [String: String]?
    var signingSessionAborterResultCall: APICallResult = .failed

    var verificationQuickCodeError: Error?
    var verificationQuickCodeResponse: VerificationQuickCodeResponse?
    var verificationQuickCodeResultCall: APICallResult = .failed

    public func registerUser(
        for _: String,
        deviceName _: String,
        activationToken _: String,
        pushToken _: String?,
        completionHandler: @escaping APIRequestCompletionHandler<RegistrationResponse>
    ) {
        completionHandler(registrationResultCall, registrationResponse, registerUserError)
    }

    func signature(
        for _: String,
        regOTT _: String,
        publicKey _: String,
        completionHandler: @escaping APIRequestCompletionHandler<SignatureResponse>
    ) {
        completionHandler(signatureResultCall, signatureResponse, signatureError)
    }

    public func getClientSecret2(
        for _: URL,
        completionHandler: @escaping APIRequestCompletionHandler<ClientSecretResponse>
    ) {
        completionHandler(clientSecretResultCall, clientSecretResponse, clientSecretError)
    }

    func pass1(
        for _: String,
        mpinId _: String,
        publicKey _: String?,
        uValue _: String,
        scope _: [String],
        completionHandler: @escaping APIRequestCompletionHandler<Pass1Response>
    ) {
        completionHandler(pass1ResultCall, pass1Response, pass1Error)
    }

    func pass2(
        for _: String,
        accessId _: String?,
        vValue _: String,
        completionHandler: @escaping APIRequestCompletionHandler<Pass2Response>
    ) {
        completionHandler(pass2ResultCall, pass2Response, pass2Error)
    }

    func authenticate(
        authOTT _: String,
        completionHandler: @escaping APIRequestCompletionHandler<AuthenticateResponse>
    ) {
        completionHandler(
            authenticationResponseManager.authenticateResultCall,
            authenticationResponseManager.authenticateResponse,
            authenticationResponseManager.authenticateError
        )

        authenticationResponseManager.updateState()
    }

    func signingClientSecret1(
        publicKey _: String,
        signingRegistrationToken _: String,
        deviceName _: String,
        completionHandler: @escaping APIRequestCompletionHandler<SigningClientSecret1Response>
    ) {
        completionHandler(signingClientSecret1ResultCall, signingClientSecret1Response, signingClientSecret1Error)
    }

    func verifyUser(
        projectId _: String,
        userId _: String,
        deviceName _: String,
        accessId _: String?,
        mpinId _: String?,
        completionHandler: @escaping APIRequestCompletionHandler<VerificationRequestResponse>
    ) {
        completionHandler(verificationResultCall, verificationResponse, verificationError)
    }

    func getSessionDetails(
        accessId _: String,
        completionHandler: @escaping APIRequestCompletionHandler<AuthenticationSessionsDetailsResponse>
    ) {
        completionHandler(sessionDetailsResultCall, sessionDetailsResponse, sessionDetailsError)
    }

    func abortSession(
        accessId _: String,
        completionHandler: @escaping APIRequestCompletionHandler<[String: String]>
    ) {
        completionHandler(sessionAborterResultCall, sessionAborterResponse, sessionAborterError)
    }

    func getSigningSessionDetails(
        accessId _: String,
        completionHandler: @escaping APIRequestCompletionHandler<SigningSessionDetailsResponse>
    ) {
        completionHandler(
            signingSessionDetailsResultCall,
            signingSessionDetailsResponse,
            signingSessionDetailsError
        )
    }

    func updateSigningSession(
        identifier _: String,
        signature _: Signature,
        timestamp _: Date,
        completionHandler:
        @escaping APIRequestCompletionHandler<SigningSessionCompleterResponse>
    ) {
        completionHandler(
            signingSessionCompleterResultCall,
            signingSessionCompleterResponse,
            signingSessionCompleterError
        )
    }

    func confirmVerificationRequest(
        userId _: String,
        code _: String,
        completionHandler: @escaping APIRequestCompletionHandler<VerificationConfirmationResponse>
    ) {
        completionHandler(
            verificationConfirmationResultCall,
            verificationConfirmationResponse,
            verificationConfirmationError
        )
    }

    func abortSigningSession(
        sessionId _: String,
        completionHandler: @escaping APIRequestCompletionHandler<[String: String]>
    ) {
        completionHandler(
            signingSessionAborterResultCall,
            signingSessionAborterResponse,
            signingSessionAborterError
        )
    }

    func quickCodeVerificationRequest(
        projectId _: String,
        jwt _: String,
        deviceName _: String,
        completionHandler: APIRequestCompletionHandler<VerificationQuickCodeResponse>
    ) {
        completionHandler(
            verificationQuickCodeResultCall,
            verificationQuickCodeResponse,
            verificationQuickCodeError
        )
    }

    func updateCodeStatus(
        accessId _: String,
        userId _: String,
        completionHandler _: @escaping APIRequestCompletionHandler<[String: String]>
    ) {}
}
