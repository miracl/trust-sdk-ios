@testable import MIRACLTrust

struct MockAuthenticator: AuthenticatorBlueprint {
    var completionHandler: AuthenticationResultCompletionHandler

    var result: Result<AuthenticateResponse, Error>

    func authenticate() {
        Task { @MainActor in
            completionHandler(result)
        }
    }
}
