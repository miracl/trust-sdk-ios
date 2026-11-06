import MIRACLTrust
import SwiftUI

struct AuthenticationView: View {
    let userId: String
    @Binding var navigationPath: [Destination]
    let onError: (String) -> Void

    @State private var pinCode = ""
    @State private var user: User?
    @State private var isProcessing = false
    @State private var processPinHandler: ProcessPinHandler?

    var body: some View {
        Group {
            if let pinHandler = processPinHandler, let targetUser = user {
                Form {
                    Section(header: Text(userId)) {
                        SecureField("Enter PIN", text: $pinCode)
                            .keyboardType(.numberPad)
                            .disabled(isProcessing)
                            .onChange(of: pinCode) { _, newValue in
                                if newValue.count > targetUser.pinLength {
                                    pinCode = String(newValue.prefix(targetUser.pinLength))
                                }
                            }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    PrimaryButton(
                        title: "Authenticate",
                        isLoading: isProcessing,
                        isDisabled: pinCode.count != targetUser.pinLength || isProcessing
                    ) {
                        isProcessing = true
                        let currentPinHandler = pinHandler
                        processPinHandler = nil
                        currentPinHandler(pinCode)
                    }
                    .padding()
                }
            } else {
                VStack {
                    Spacer()
                    ProgressView("Preparing authentication...")
                    Spacer()
                }
            }
        }
        .navigationTitle("Authenticate")
        .navigationBarTitleDisplayMode(.inline)
        .task { await startAuthentication() }
        .onDisappear {
            // Cancel pending authentication if the user pops this view off the navigation stack
            if let pinHandler = processPinHandler {
                processPinHandler = nil
                pinHandler(nil)
            }
        }
    }

    private func startAuthentication() async {
        do {
            let miraclTrust = MIRACLTrust.getInstance()
            guard let targetUser = try await miraclTrust.getUser(userId: userId) else { return }
            user = targetUser

            let jwtToken = try await miraclTrust.authenticate(user: targetUser) { processPinHandler in
                self.processPinHandler = processPinHandler
            }
            navigationPath = [.authenticationSuccessful(jwtToken: jwtToken)]
        } catch is CancellationError, AuthenticationError.pinCancelled {
            return
        } catch AuthenticationError.revoked {
            navigationPath = [.revoked(userId: userId)]
        } catch {
            onError(error.localizedDescription)
            pinCode = ""
            isProcessing = false
            await startAuthentication()
        }
    }
}
