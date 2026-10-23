import MIRACLTrust
import SwiftUI

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
            fatalError("Failed to configure MIRACL Trust SDK: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
