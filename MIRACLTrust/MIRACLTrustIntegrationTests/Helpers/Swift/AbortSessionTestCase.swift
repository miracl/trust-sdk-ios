@testable import MIRACLTrust
import XCTest

class AbortSessionTestCase: XCTest {
    func abortSession(sessionDetails: AuthenticationSessionDetails) async -> (Bool, Error?) {
        await withCheckedContinuation { continuation in
            MIRACLTrust.getInstance().abortAuthenticationSession(authenticationSessionDetails: sessionDetails) { isAborted, error in
                continuation.resume(returning: (isAborted, error))
            }
        }
    }
}
