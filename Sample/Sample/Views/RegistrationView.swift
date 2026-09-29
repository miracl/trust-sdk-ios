import MIRACLTrust
import SwiftUI

private let minPinLength = 4
private let maxPinLength = 6

struct RegistrationView: View {
    let url: URL
    @Binding var navigationPath: [Destination]
    let onError: (String) -> Void

    @State private var pinCode = ""
    @State private var userId = ""
    @State private var isProcessing = false
    @State private var processPinHandler: ProcessPinHandler?

    var body: some View {
        Group {
            if let pinHandler = processPinHandler {
                Form {
                    Section(header: Text(userId)) {
                        SecureField("Choose PIN", text: $pinCode)
                            .keyboardType(.numberPad)
                            .disabled(isProcessing)
                            .onChange(of: pinCode) { _, newValue in
                                if newValue.count > maxPinLength {
                                    pinCode = String(newValue.prefix(maxPinLength))
                                }
                            }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    PrimaryButton(
                        title: "Register",
                        isLoading: isProcessing,
                        isDisabled: pinCode.count < minPinLength || isProcessing
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
                    ProgressView("Processing verification link...")
                    Spacer()
                }
            }
        }
        .navigationTitle("Register Device")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: url) { startRegistration() }
        .onDisappear {
            // Cancel pending registration if the user pops this view off the navigation stack
            if let pinHandler = processPinHandler {
                processPinHandler = nil
                pinHandler(nil)
            }
        }
    }

    private func startRegistration() {
        MIRACLTrust.getInstance().getActivationToken(verificationURL: url) { tokenResponse, error in
            if let error = error {
                if let tokenError = error as? ActivationTokenError,
                   case let .unsuccessfulVerification(response) = tokenError,
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
            userId = tokenResponse.userId

            MIRACLTrust.getInstance().register(
                for: tokenResponse.userId,
                activationToken: tokenResponse.activationToken,
                didRequestPinHandler: { processPinHandler in
                    self.processPinHandler = processPinHandler
                },
                completionHandler: { _, error in
                    if let error = error {
                        // Ignore cancellation when user navigates back
                        if case RegistrationError.pinCancelled = error {
                            return
                        }

                        onError(error.localizedDescription)
                        navigationPath.removeAll()
                        return
                    }

                    navigationPath = []
                }
            )
        }
    }
}
