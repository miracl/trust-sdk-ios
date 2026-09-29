import SwiftUI

struct AuthenticationResultView: View {
    let jwtToken: String
    @Binding var navigationPath: [Destination]
    
    private let jwtDocsUrl = URL(string: "https://miracl.com/docs/guides/authentication/jwt-verification/")!
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("The result of the authentication is a signed JSON Web Token (JWT). To properly finish the authentication process, the token must be sent to the application server for verification.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Link("Read JWT Verification Guide", destination: jwtDocsUrl)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("JWT Payload")
                            .font(.headline)
                        
                        Text(jwtToken)
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
            
            VStack {
                Button(action: {
                    navigationPath.removeAll()
                }) {
                    Text("Done")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .navigationTitle("Authentication Result")
        .navigationBarTitleDisplayMode(.inline)
    }
}
