import MIRACLTrust
import SwiftUI

enum Destination: Hashable {
    case enterUserId(userId: String = "")
    case emailSent(userId: String)
    case registration(url: URL)
    case authentication(userId: String)
    case authenticationSuccessful(jwtToken: String)
    case revoked(userId: String)
}

struct ContentView: View {
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
                    case let .enterUserId(userId):
                        EnterUserIdView(userId: userId, navigationPath: $navigationPath, onError: showError)
                    case let .emailSent(userId):
                        EmailSentView(userId: userId)
                    case let .registration(url):
                        RegistrationView(url: url, navigationPath: $navigationPath, onError: showError)
                    case let .authentication(userId):
                        AuthenticationView(userId: userId, navigationPath: $navigationPath, onError: showError)
                    case let .authenticationSuccessful(jwtToken):
                        AuthenticationResultView(jwtToken: jwtToken, navigationPath: $navigationPath)
                    case let .revoked(userId):
                        RevokedView(userId: userId, navigationPath: $navigationPath, onError: showError)
                    }
                }
        }
        .onOpenURL { url in
            guard url.path.hasPrefix("/verification/confirmation") else { return }

            navigationPath = [.registration(url: url)]
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
