import MIRACLTrust

struct ActivationTokenAsyncCase {
    let platformAPI = PlatformAPIWrapper()

    func getActivationToken(
        serviceAccountToken: String,
        projectId: String,
        projectURL: String,
        userId: String,
        accessId: String? = nil
    ) async throws -> String {
        let verificationURL = try await platformAPI.getVerificationURL(
            serviceAccountToken: serviceAccountToken,
            projectId: projectId,
            projectURL: projectURL,
            userId: userId,
            accessId: accessId
        )

        return try await withCheckedThrowingContinuation { continuation in
            MIRACLTrust.getInstance().getActivationToken(verificationURL: verificationURL) { response, error in
                if let response {
                    continuation.resume(returning: response.activationToken)
                } else if let error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
