import Foundation

protocol APIBlueprint: Sendable {
    func registerUser(
        userId: String,
        activationToken: String,
        deviceName: String,
        publicKey: String,
        pushToken: String?,
        deviceTag: String,
        completionHandler: @escaping APIRequestCompletionHandler<RegistrationResponse>
    )

    func getTAShare(
        designatedTA: DesignatedTA,
        mpinId: String,
        publicKey: String,
        completionHandler: @escaping APIRequestCompletionHandler<TAShareResponse>
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

    func verifyUser(
        projectId: String,
        userId: String,
        deviceName: String,
        accessId: String?,
        deviceTag: String,
        completionHandler: @escaping APIRequestCompletionHandler<VerificationRequestResponse>
    )

    func confirmVerificationRequest(
        userId: String,
        code: String,
        deviceTag: String,
        completionHandler: @escaping APIRequestCompletionHandler<VerificationConfirmationResponse>
    )

    func getCrossDeviceSession(
        sessionId: String,
        completionHandler: @escaping APIRequestCompletionHandler<CrossDeviceSessionResponse>
    )

    func getSessionDetails(
        accessId: String,
        completionHandler: @escaping APIRequestCompletionHandler<AuthenticationSessionsDetailsResponse>
    )

    func updateCrossDeviceSessionForSigning(
        sessionId: String,
        signature: String,
        completionHandler: @escaping APIRequestCompletionHandler<[String: String]>
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

    func quickCodeVerificationRequest(
        projectId: String,
        jwt: String,
        deviceName: String,
        completionHandler: @escaping APIRequestCompletionHandler<VerificationQuickCodeResponse>
    )
}
