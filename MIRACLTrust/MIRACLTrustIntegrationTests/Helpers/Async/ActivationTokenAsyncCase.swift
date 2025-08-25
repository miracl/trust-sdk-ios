import MIRACLTrust

struct ActivationTokenAsyncCase {
    let platformAPI = PlatformAPIWrapper()

    func getActivationToken(
        clientId: String,
        clientSecret: String,
        projectId: String,
        projectURL: String,
        userId: String,
        accessId: String? = nil
    ) async throws -> String {
        let verificationURL = try await platformAPI.getVerificationURL(
            clientId: clientId,
            clientSecret: clientSecret,
            projectId: projectId,
            projectURL: projectURL,
            userId: userId,
            accessId: accessId
        )

        let activationToken: String = try await withCheckedThrowingContinuation { continuation in
            MIRACLTrust.getInstance().getActivationToken(verificationURL: verificationURL) { response, error in
                if let response {
                    continuation.resume(returning: response.activationToken)
                } else if let error {
                    continuation.resume(throwing: error)
                }
            }
        }

        return activationToken
    }
}
