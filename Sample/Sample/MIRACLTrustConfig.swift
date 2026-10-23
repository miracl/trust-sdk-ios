import Foundation

enum MIRACLTrustConfig {
    /// MIRACL Trust Project ID
    static let projectId: String = {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "MIRACLProjectId") as? String,
            !value.isEmpty,
            value != "YOUR_PROJECT_ID"
        else {
            fatalError("Set your MIRACL_PROJECT_ID in Config.xcconfig")
        }
        return value
    }()

    /// MIRACL Trust Project Domain string (e.g., "example.miracl.io")
    static let projectDomain: String = {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: "MIRACLProjectDomain") as? String,
            !value.isEmpty,
            value != "YOUR_PROJECT_DOMAIN"
        else {
            fatalError("Set your MIRACL_PROJECT_DOMAIN in Config.xcconfig")
        }

        if value.contains("://") {
            fatalError("MIRACLProjectDomain must be a raw host without a scheme (e.g. 'example.miracl.io')")
        }

        return value
    }()

    /// Full HTTPS MIRACL Trust Project URL string (e.g., "https://example.miracl.io")
    static var projectURL: String {
        "https://\(projectDomain)"
    }
}
