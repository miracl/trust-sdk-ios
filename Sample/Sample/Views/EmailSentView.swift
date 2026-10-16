import SwiftUI
import MIRACLTrust

struct EmailSentView: View {
    let userId: String

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Verification Sent")
                .font(.title2.bold())

            Text("A verification email has been sent to:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(userId)
                .font(.headline)

            Text("Open the verification link on this device to complete registration.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)

            Spacer()
        }
        .navigationTitle("Email Sent")
        .navigationBarTitleDisplayMode(.inline)
    }
}
