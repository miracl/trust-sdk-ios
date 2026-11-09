import MIRACLTrust
import SwiftUI

struct EnterUserIdView: View {
    @State var userId: String
    @Binding var navigationPath: [Destination]
    let onError: (String) -> Void

    @State private var isProcessing = false
    @State private var handlingTask: Task<Void, Never>?

    var body: some View {
        Form {
            Section {
                TextField("User ID (Email)", text: $userId)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(isProcessing)
            }
        }
        .onDisappear {
            handlingTask?.cancel()
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: "Send Verification Email",
                isLoading: isProcessing,
                isDisabled: userId.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing
            ) {
                sendVerificationEmail()
            }
            .padding()
        }
        .navigationTitle("Enter User ID")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendVerificationEmail() {
        handlingTask?.cancel()
        handlingTask = Task {
            defer { isProcessing = false }
            isProcessing = true

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
