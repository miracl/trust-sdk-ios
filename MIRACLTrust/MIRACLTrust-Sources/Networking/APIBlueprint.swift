import Foundation

protocol APIBlueprint: Sendable {
    func registerUser(
        for userId: String,
        deviceName: String,
        activationToken: String,
        pushToken: String?,
        completionHandler: @escaping APIRequestCompletionHandler<RegistrationResponse>
    )

    func signature(
        for mpinId: String,
        regOTT: String,
        publicKey: String,
        completionHandler: @escaping APIRequestCompletionHandler<SignatureResponse>
    )

    func getClientSecret2(
        for cs2URL: URL,
        completionHandler: @escaping APIRequestCompletionHandler<ClientSecretResponse>
    )

    func pass1(
        for dtas: String,
        mpinId: String,
        publicKey: String?,
        uValue: String,
        scope: [String],
        completionHandler: @escaping APIRequestCompletionHandler<Pass1Response>
    )

    func pass2(
        for mpinId: String,
        accessId: String?,
        vValue: String,
        completionHandler: @escaping APIRequestCompletionHandler<Pass2Response>
    )

    func authenticate(
        authOTT: String,
        completionHandler: @escaping APIRequestCompletionHandler<AuthenticateResponse>
    )

    func signingClientSecret1(
        publicKey: String,
        signingRegistrationToken: String,
        deviceName: String,
        completionHandler: @escaping APIRequestCompletionHandler<SigningClientSecret1Response>
    )

    func verifyUser(
        projectId: String,
        userId: String,
        deviceName: String,
        accessId: String?,
        mpinId: String?,
        completionHandler: @escaping APIRequestCompletionHandler<VerificationRequestResponse>
    )

    func confirmVerificationRequest(
        userId: String,
        code: String,
        completionHandler: @escaping APIRequestCompletionHandler<VerificationConfirmationResponse>
    )

    func getSessionDetails(
        accessId: String,
        completionHandler: @escaping APIRequestCompletionHandler<AuthenticationSessionsDetailsResponse>
    )

    func abortSession(
        accessId: String,
        completionHandler: @escaping APIRequestCompletionHandler<[String: String]>
    )

    func updateCodeStatus(
        accessId: String,
        userId: String,
        completionHandler: @escaping APIRequestCompletionHandler<[String: String]>
    )

    func getSigningSessionDetails(
        accessId: String,
        completionHandler: @escaping APIRequestCompletionHandler<SigningSessionDetailsResponse>
    )

    func updateSigningSession(
        identifier: String,
        signature: Signature,
        timestamp: Date,
        completionHandler: @escaping APIRequestCompletionHandler<SigningSessionCompleterResponse>
    )

    func abortSigningSession(
        sessionId: String,
        completionHandler: @escaping APIRequestCompletionHandler<[String: String]>
    )

    func quickCodeVerificationRequest(
        projectId: String,
        jwt: String,
        deviceName: String,
        completionHandler: @escaping APIRequestCompletionHandler<VerificationQuickCodeResponse>
    )
}
