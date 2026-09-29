import SwiftUI
import MIRACLTrust

struct AuthenticationView: View {
    let userId: String
    @Binding var navigationPath: [Destination]
    let onError: (String) -> Void

    @State private var pinCode = ""
    @State private var user: User?
    @State private var isProcessing = false
    @State private var pinProcessor: ((String?) -> Void)?

    var body: some View {
        Group {
            if let processor = pinProcessor, let targetUser = user {
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
                        let currentProcessor = processor
                        pinProcessor = nil
                        currentProcessor(pinCode)
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
        .onAppear { startAuthentication() }
    }

    private func startAuthentication() {
        guard let targetUser = MIRACLTrust.getInstance().getUser(by: userId) else { return }
        self.user = targetUser

        MIRACLTrust.getInstance().authenticate(
            user: targetUser,
            didRequestPinHandler: { processor in
                self.pinProcessor = processor
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
