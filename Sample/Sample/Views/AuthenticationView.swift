import SwiftUI
import MIRACLTrust

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
                    Button {
                        isProcessing = true
                        let currentPinHandler = pinHandler
                        processPinHandler = nil
                        currentPinHandler(pinCode)
                    } label: {
                        HStack {
                            Spacer()
                            if isProcessing {
                                ProgressView()
                            } else {
                                Text("Authenticate")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(pinCode.count != targetUser.pinLength || isProcessing)
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
        .task { startAuthentication() }
    }

    private func startAuthentication() {
        guard let targetUser = MIRACLTrust.getInstance().getUser(by: userId) else { return }
        self.user = targetUser

        MIRACLTrust.getInstance().authenticate(
            user: targetUser,
            didRequestPinHandler: { processPinHandler in
                self.processPinHandler = processPinHandler
            },
            completionHandler: { jwtToken, error in
                if let error = error {
                    if let authError = error as? AuthenticationError, case .revoked = authError {
                        navigationPath = [.revoked(userId: userId)]
                    } else {
                        onError(error.localizedDescription)
                        pinCode = ""
                        isProcessing = false
                        startAuthentication()
                    }
                } else if let jwtToken = jwtToken {
                    navigationPath = [.authenticationSuccessful(jwtToken: jwtToken)]
                }
            }
        )
    }
}
