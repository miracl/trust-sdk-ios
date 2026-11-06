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
        .task(id: url) { await startRegistration() }
        .onDisappear {
            // Cancel pending registration if the user pops this view off the navigation stack
            if let pinHandler = processPinHandler {
                processPinHandler = nil
                pinHandler(nil)
            }
        }
    }

    private func startRegistration() async {
        do {
            let miraclTrust = MIRACLTrust.getInstance()
            let activationTokenResponse = try await miraclTrust.getActivationToken(verificationURL: url)
            userId = activationTokenResponse.userId

            _ = try await miraclTrust.register(userId: activationTokenResponse.userId, activationToken: activationTokenResponse.activationToken) { processPinHandler in
                self.processPinHandler = processPinHandler
            }

            navigationPath = []
        } catch is CancellationError, RegistrationError.pinCancelled {
            // User intentionally cancelled PIN entry; dismiss silently
            return
        } catch {
            handleRegistrationFailure(error)
        }
    }

    private func handleRegistrationFailure(_ error: Error) {
        switch error {
        case let ActivationTokenError.unsuccessfulVerification(.some(response)):
            let resendUserId = response.userId
            onError("Verification link expired for \(resendUserId). Please request a new link.")
            navigationPath = [.enterUserId(userId: resendUserId)]

        default:
            onError(error.localizedDescription)
            navigationPath.removeAll()
        }
    }
}
