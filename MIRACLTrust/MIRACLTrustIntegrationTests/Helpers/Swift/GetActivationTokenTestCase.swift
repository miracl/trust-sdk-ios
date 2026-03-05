@testable import MIRACLTrust
import XCTest

class GetActivationTokenTestCase: XCTest {
    let api = PlatformAPIWrapper()

    func getActivationToken(
        serviceAccountToken: String,
        projectId: String,
        projectURL: String,
        userId: String,
        accessId: String? = nil
    ) async -> (ActivationTokenResponse?, Error?) {
        do {
            let verificationURL = try await api.getVerificationURL(serviceAccountToken: serviceAccountToken, projectId: projectId, projectURL: projectURL, userId: userId, accessId: accessId)

            return await withCheckedContinuation { continuation in
                MIRACLTrust.getInstance().getActivationToken(verificationURL: verificationURL) { activationTokenResponse, error in
                    continuation.resume(returning: (activationTokenResponse, error))
                }
            }
        } catch {
            return (nil, error)
        }
    }

    func getActivationToken(verificationURL: URL) async -> (ActivationTokenResponse?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().getActivationToken(verificationURL: verificationURL) { activationTokenResponse, error in
                continuation.resume(returning: (activationTokenResponse, error))
            }
        }
    }

    func getActivationToken(userId: String, code: String) async -> (ActivationTokenResponse?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().getActivationToken(userId: userId, code: code) { activationTokenResponse, error in
                continuation.resume(returning: (activationTokenResponse, error))
            }
        }
    }
}
