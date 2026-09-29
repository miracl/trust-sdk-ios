import SwiftUI
import MIRACLTrust

enum Destination: Hashable {
    case enterUserId(userId: String = "")
    case emailSent(userId: String)
    case registration(url: URL)
    case authentication(userId: String)
    case authenticationSuccessful(jwtToken: String)
    case revoked(userId: String)
}

struct ContentView: View {
    @Binding var deepLinkURL: URL?
    @State private var navigationPath: [Destination] = []
    @State private var errorMessage: String?
    
    private var isErrorAlertPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            HomeView(navigationPath: $navigationPath, onError: showError)
                .navigationDestination(for: Destination.self) { destination in
                    switch destination {
                    case .enterUserId(let userId):
                        EnterUserIdView(userId: userId, navigationPath: $navigationPath, onError: showError)
                    case .emailSent(let userId):
                        EmailSentView(userId: userId)
                    case .registration(let url):
                        RegistrationView(url: url, navigationPath: $navigationPath, onError: showError)
                    case .authentication(let userId):
                        AuthenticationView(userId: userId, navigationPath: $navigationPath, onError: showError)
                    case .authenticationSuccessful(let jwtToken):
                        AuthenticationResultView(jwtToken: jwtToken, navigationPath: $navigationPath)
                    case .revoked(let userId):
                        RevokedView(userId: userId, navigationPath: $navigationPath, onError: showError)
                    }
                }
        }
        .task(id: deepLinkURL) {
            if let url = deepLinkURL {
                navigationPath = [.registration(url: url)]
                deepLinkURL = nil
            }
        }
        .alert("Error", isPresented: isErrorAlertPresented) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
    }
}
