protocol AuthenticatorBlueprint: Sendable {
    var completionHandler: AuthenticateCompletionHandler { get set }
    func authenticate()
}
