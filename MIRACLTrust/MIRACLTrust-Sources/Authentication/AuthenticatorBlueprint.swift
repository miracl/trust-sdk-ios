protocol AuthenticatorBlueprint: Sendable {
    var completionHandler: AuthenticationResultCompletionHandler { get set }
    func authenticate()
}
