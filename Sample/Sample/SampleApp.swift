import SwiftUI
import MIRACLTrust

@main
struct SampleApp: App {
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
            ContentView()
        }
    }
}
