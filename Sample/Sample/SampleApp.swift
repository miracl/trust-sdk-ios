import SwiftUI
import MIRACLTrust

@main
struct SampleApp: App {
    @State private var deepLinkURL: URL?
    
    init() {
        do {
            let config = try Configuration.Builder(
                projectId: MIRACLTrustConfig.projectId,
                projectURL: MIRACLTrustConfig.projectURL
            ).build()
            
            try MIRACLTrust.configure(with: config)
        } catch {
            fatalError(
                "MIRACL Trust SDK Configuration Error: \(error.localizedDescription)\n" +
                "Please verify 'MIRACL_PROJECT_ID' and 'MIRACL_PROJECT_DOMAIN' in 'Config.xcconfig'."
            )
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(deepLinkURL: $deepLinkURL)
                .onOpenURL { url in
                    deepLinkURL = extractVerificationURL(from: url)
                }
        }
    }
    
    private func extractVerificationURL(from url: URL) -> URL? {
        guard let scheme = url.scheme, scheme.lowercased() == "https",
              let host = url.host, host.lowercased() == MIRACLTrustConfig.projectDomain.lowercased(),
              url.path.hasPrefix("/verification/confirmation") else {
            return nil
        }
        return url
    }
}
