@testable import MIRACLTrust
import XCTest

class VerificationTestCase {
    func sendVerificationEmail(
        userId: String,
        authenticationSessionDetails: AuthenticationSessionDetails? = nil
    ) async -> (VerificationResponse?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().sendVerificationEmail(
                userId: userId,
                authenticationSessionDetails: authenticationSessionDetails
            ) { result, error in
                continuation.resume(returning: (result, error))
            }
        }
    }

    func sendVerificationEmailForCrossDeviceSession(
        userId: String,
        crossDeviceSession: CrossDeviceSession? = nil
    ) async -> (VerificationResponse?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance()._sendVerificationEmail(
                userId: userId,
                crossDeviceSession: crossDeviceSession
            ) { result, error in
                continuation.resume(returning: (result, error))
            }
        }
    }
}
