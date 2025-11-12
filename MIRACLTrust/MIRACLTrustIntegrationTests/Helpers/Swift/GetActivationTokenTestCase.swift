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
    ) -> (ActivationTokenResponse?, Error?) {
        let waitForToken = XCTestExpectation(description: "wait for activation Token")
        nonisolated(unsafe) var returnedActivationTokenResponse: ActivationTokenResponse?
        nonisolated(unsafe) var returnedError: Error?

        let verificationURL = api.getVerificaitonURL(
            serviceAccountToken: serviceAccountToken,
            projectId: projectId,
            projectURL: projectURL,
            userId: userId,
            accessId: accessId
        )

        MIRACLTrust.getInstance().getActivationToken(verificationURL: verificationURL!) { activationTokenResponse, error in
            returnedActivationTokenResponse = activationTokenResponse
            returnedError = error

            waitForToken.fulfill()
        }

        _ = XCTWaiter.wait(for: [waitForToken], timeout: operationTimeout)
        return (returnedActivationTokenResponse, returnedError)
    }

    func getActivationToken(verificationURL: URL) -> (ActivationTokenResponse?, Error?) {
        let waitForToken = XCTestExpectation(description: "wait for activation Token")
        nonisolated(unsafe) var returnedActivationTokenResponse: ActivationTokenResponse?
        nonisolated(unsafe) var returnedError: Error?

        MIRACLTrust.getInstance().getActivationToken(verificationURL: verificationURL) { activationTokenResponse, error in
            returnedActivationTokenResponse = activationTokenResponse
            returnedError = error

            waitForToken.fulfill()
        }

        _ = XCTWaiter.wait(for: [waitForToken], timeout: operationTimeout)
        return (returnedActivationTokenResponse, returnedError)
    }

    func getActivationToken(userId: String, code: String) -> (ActivationTokenResponse?, Error?) {
        let waitForToken = XCTestExpectation(description: "wait for activation Token")
        nonisolated(unsafe) var returnedActivationTokenResponse: ActivationTokenResponse?
        nonisolated(unsafe) var returnedError: Error?

        MIRACLTrust.getInstance().getActivationToken(userId: userId, code: code) { activationTokenResponse, error in
            returnedActivationTokenResponse = activationTokenResponse
            returnedError = error

            waitForToken.fulfill()
        }

        _ = XCTWaiter.wait(for: [waitForToken], timeout: operationTimeout)
        return (returnedActivationTokenResponse, returnedError)
    }
}
