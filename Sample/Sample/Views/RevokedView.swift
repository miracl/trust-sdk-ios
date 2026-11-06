import MIRACLTrust
import SwiftUI

struct RevokedView: View {
    let userId: String
    @Binding var navigationPath: [Destination]
    let onError: (String) -> Void

    @State private var isProcessing = false
    @State private var handlingTask: Task<Void, Never>?

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

            PrimaryButton(
                title: "Send Verification Email",
                isLoading: isProcessing,
                isDisabled: isProcessing
            ) {
                sendVerificationEmail()
            }
            .padding()
        }
        .onDisappear {
            handlingTask?.cancel()
        }
        .navigationTitle("Disabled")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendVerificationEmail() {
        isProcessing = true
        handlingTask?.cancel()
        handlingTask = Task {
            defer { isProcessing = false }

            do {
                _ = try await MIRACLTrust.getInstance().sendVerificationEmail(userId: userId)
                navigationPath.append(.emailSent(userId: userId))
            } catch let VerificationError.requestBackoff(backoff) {
                let currentSeconds = Int64(Date().timeIntervalSince1970)
                let remainingSeconds = max(1, backoff - currentSeconds)
                onError("You’ve requested too many verification emails. Try again in \(remainingSeconds) seconds.")
            } catch is CancellationError {
                return
            } catch {
                onError(error.localizedDescription)
            }
        }
    }
}
