import SwiftUI
import MIRACLTrust

struct RevokedView: View {
    let userId: String
    @Binding var navigationPath: [Destination]
    let onError: (String) -> Void

    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "exclamationmark.octagon.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)

            Text("Device Disabled")
                .font(.title2.bold())

            Text(userId)
                .font(.headline)

            Text("To re-enable this device, verify your identity again.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                sendVerificationEmail()
            } label: {
                HStack {
                    Spacer()
                    if isProcessing {
                        ProgressView()
                    } else {
                        Text("Send Verification Email")
                            .bold()
                    }
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isProcessing)
            .padding(.horizontal)
        }
        .navigationTitle("Disabled")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendVerificationEmail() {
        isProcessing = true
        MIRACLTrust.getInstance().sendVerificationEmail(userId: userId) { _, error in
            isProcessing = false
            if let error = error {
                if let verificationError = error as? VerificationError,
                   case .requestBackoff(let backoff) = verificationError {
                    let currentSeconds = Int64(Date().timeIntervalSince1970)
                    let remainingSeconds = max(1, backoff - currentSeconds)
                    onError("You’ve requested too many verification emails. Try again in \(remainingSeconds) seconds.")
                } else {
                    onError(error.localizedDescription)
                }
            } else {
                navigationPath.append(.emailSent(userId: userId))
            }
        }
    }
}
