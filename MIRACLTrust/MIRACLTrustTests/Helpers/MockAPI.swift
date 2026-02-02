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

class ClientSecretResponsesManager: @unchecked Sendable {
    var retryEnabled = false
    var retryEnabledForSecondClientSecret = false
    var retryInProgress = false

    var clientSecret1Error: Error?
    var clientSecret1Response: ClientSecretResponse?
    var clientSecret1ResultCall: APICallResult = .failed

    var clientSecret1RetryError: Error?
    var clientSecret1RetryResponse: ClientSecretResponse?
    var clientSecret1RetryResultCall: APICallResult = .failed

    var clientSecret2Error: Error?
    var clientSecret2Response: ClientSecretResponse?
    var clientSecret2ResultCall: APICallResult = .failed

    var clientSecret2RetryError: Error?
    var clientSecret2RetryResponse: ClientSecretResponse?
    var clientSecret2RetryResultCall: APICallResult = .failed

    var isSecondRequest = false
}

struct MockAPI: APIBlueprint {
    var clientSecretResponsesManager = ClientSecretResponsesManager()

    var pass1Error: Error?
    var pass1Response: Pass1Response?
    var pass1ResultCall: APICallResult = .failed

    var pass2Error: Error?
    var pass2Response: Pass2Response?
    var pass2ResultCall: APICallResult = .failed

    var authenticationResponseManager = AuthenticationResponseManager()

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

    var verificationQuickCodeError: Error?
    var verificationQuickCodeResponse: VerificationQuickCodeResponse?
    var verificationQuickCodeResultCall: APICallResult = .failed

    var registrationError: Error?
    var registrationResponse: RegistrationResponse?
    var registrationResultCall: APICallResult = .failed

    var crossDeviceSessionError: Error?
    var crossDeviceSessionResponse: CrossDeviceSessionResponse?
    var crossDeviceSessionResultCall: APICallResult = .failed

    var updateCrossDeviceSessionError: Error?
    var updateCrossDeviceSessionResponse: [String: String]?
    var updateCrossDeviceSessionResultCall: APICallResult = .failed

    func getClientSecretShare(
        _: URL,
        completionHandler: @escaping APIRequestCompletionHandler<ClientSecretResponse>
    ) {
        if clientSecretResponsesManager.retryEnabled {
            if clientSecretResponsesManager.retryInProgress {
                completionHandler(
                    clientSecretResponsesManager.clientSecret1RetryResultCall,
                    clientSecretResponsesManager.clientSecret1RetryResponse,
                    clientSecretResponsesManager.clientSecret1RetryError
                )
            } else {
                clientSecretResponsesManager.retryInProgress = true

                completionHandler(
                    clientSecretResponsesManager.clientSecret1ResultCall,
                    clientSecretResponsesManager.clientSecret1Response,
                    clientSecretResponsesManager.clientSecret1Error
                )
            }
        } else if clientSecretResponsesManager.retryEnabledForSecondClientSecret {
            if clientSecretResponsesManager.isSecondRequest {
                if clientSecretResponsesManager.retryInProgress {
                    completionHandler(
                        clientSecretResponsesManager.clientSecret2RetryResultCall,
                        clientSecretResponsesManager.clientSecret2RetryResponse,
                        clientSecretResponsesManager.clientSecret2RetryError
                    )
                } else {
                    clientSecretResponsesManager.retryInProgress = true

                    completionHandler(
                        clientSecretResponsesManager.clientSecret2ResultCall,
                        clientSecretResponsesManager.clientSecret2Response,
                        clientSecretResponsesManager.clientSecret2Error
                    )
                }
            } else {
                clientSecretResponsesManager.isSecondRequest = true
                completionHandler(
                    clientSecretResponsesManager.clientSecret1ResultCall,
                    clientSecretResponsesManager.clientSecret1Response,
                    clientSecretResponsesManager.clientSecret1Error
                )
            }

        } else {
            if clientSecretResponsesManager.isSecondRequest {
                completionHandler(
                    clientSecretResponsesManager.clientSecret2ResultCall,
                    clientSecretResponsesManager.clientSecret2Response,
                    clientSecretResponsesManager.clientSecret2Error
                )
            } else {
                clientSecretResponsesManager.isSecondRequest = true
                completionHandler(
                    clientSecretResponsesManager.clientSecret1ResultCall,
                    clientSecretResponsesManager.clientSecret1Response,
                    clientSecretResponsesManager.clientSecret1Error
                )
            }
        }
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

    func registerUser(
        userId _: String,
        activationToken _: String,
        deviceName _: String,
        publicKey _: String,
        pushToken _: String?,
        completionHandler: @escaping APIRequestCompletionHandler<RegistrationResponse>
    ) {
        completionHandler(
            registrationResultCall,
            registrationResponse,
            registrationError
        )
    }

    func getCrossDeviceSession(sessionId _: String, completionHandler: @escaping APIRequestCompletionHandler<CrossDeviceSessionResponse>) {
        completionHandler(
            crossDeviceSessionResultCall,
            crossDeviceSessionResponse,
            crossDeviceSessionError
        )
    }

    func updateCrossDeviceSessionForSigning(
        sessionId _: String,
        signature _: String,
        completionHandler: @escaping APIRequestCompletionHandler<[String: String]>
    ) {
        completionHandler(
            updateCrossDeviceSessionResultCall,
            updateCrossDeviceSessionResponse,
            updateCrossDeviceSessionError
        )
    }
}
