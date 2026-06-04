@testable import MIRACLTrust
import XCTest

class VerificationTestCase {
    func sendVerificationEmail(
        userId: String,
        authenticationSessionDetails: AuthenticationSessionDetails?
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
        crossDeviceSession: CrossDeviceSession
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

    func sendVerificationEmail(
        userId: String
    ) async -> (VerificationResponse?, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().sendVerificationEmail(
                userId: userId
            ) { result, error in
                continuation.resume(returning: (result, error))
            }
        }
    }
}
