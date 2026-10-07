import SwiftUI
import MIRACLTrust

struct EnterUserIdView: View {
    @State var userId: String
    @Binding var navigationPath: [Destination]
    let onError: (String) -> Void

    @State private var isProcessing = false

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
        .safeAreaInset(edge: .bottom) {
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
            .disabled(userId.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
            .padding()
        }
        .navigationTitle("Enter User ID")
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
