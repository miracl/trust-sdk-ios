import SwiftUI
import MIRACLTrust

struct RegistrationView: View {
    let url: URL
    @Binding var navigationPath: [Destination]
    let onError: (String) -> Void

    @State private var pinCode = ""
    @State private var userId = ""
    @State private var isProcessing = false
    @State private var pinProcessor: ((String?) -> Void)?

    var body: some View {
        Group {
            if let processor = pinProcessor {
                Form {
                    Section(header: Text(userId)) {
                        SecureField("Choose PIN", text: $pinCode)
                            .keyboardType(.numberPad)
                            .disabled(isProcessing)
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
                                Text("Register")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(pinCode.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
                    .padding()
                }
            } else {
                VStack {
                    Spacer()
                    ProgressView("Processing verification link...")
                    Spacer()
                }
            }
        }
        .navigationTitle("Register Device")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startRegistration() }
    }

    private func startRegistration() {
        MIRACLTrust.getInstance().getActivationToken(verificationURL: url) { tokenResponse, error in
            if let error = error {
                if let tokenError = error as? ActivationTokenError,
                   case .unsuccessfulVerification(let response) = tokenError,
                   let resendUserId = response?.userId {
                    onError("Verification link expired for \(resendUserId). Please request a new link.")
                    navigationPath = [.enterUserId(userId: resendUserId)]
                } else {
                    onError(error.localizedDescription)
                    navigationPath.removeAll()
                }
                return
            }

            guard let tokenResponse = tokenResponse else { return }
            self.userId = tokenResponse.userId

            MIRACLTrust.getInstance().register(
                for: tokenResponse.userId,
                activationToken: tokenResponse.activationToken,
                didRequestPinHandler: { processor in
                    self.pinProcessor = processor
                },
                completionHandler: { registeredUser, error in
                    if let error = error {
                        onError(error.localizedDescription)
                        navigationPath.removeAll()
                        return
                    }

                    guard let user = registeredUser else { return }

                    MIRACLTrust.getInstance().authenticate(
                        user: user,
                        didRequestPinHandler: { authProcessor in
                            authProcessor(self.pinCode)
                        },
                        completionHandler: { jwtToken, authError in
                            if let authError = authError {
                                onError(authError.localizedDescription)
                                navigationPath.removeAll()
                            } else if let jwtToken = jwtToken {
                                navigationPath = [.authenticationSuccessful(jwtToken: jwtToken)]
                            }
                        }
                    )
                }
            )
        }
    }
}
