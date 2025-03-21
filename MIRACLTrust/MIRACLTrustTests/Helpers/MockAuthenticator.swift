@testable import MIRACLTrust

struct MockAuthenticator: AuthenticatorBlueprint {
    var completionHandler: AuthenticateCompletionHandler

    var response: AuthenticateResponse?
    var error: Error?

    func authenticate() {
        Task { @MainActor in
            completionHandler(response, error)
        }
    }
}
