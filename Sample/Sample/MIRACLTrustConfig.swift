import Foundation

enum MIRACLTrustConfig {
    /// MIRACL Trust Project ID
    static let projectId: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "MIRACLProjectId") as? String, !value.isEmpty else {
            fatalError("MIRACLProjectId is missing from Info.plist or Config.xcconfig")
        }
        return value
    }()
    
    /// MIRACL Trust Project Domain string (e.g., "example.miracl.io")
    static let projectDomain: String = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "MIRACLProjectDomain") as? String, !value.isEmpty else {
            fatalError("MIRACLProjectDomain is missing from Info.plist or Config.xcconfig")
        }
        
        if value.contains("://") {
            fatalError("MIRACLProjectDomain in Config.xcconfig must be a raw host with no protocol scheme (e.g., 'example.miracl.io').")
        }
        
        return value
    }()
    
    /// Full HTTPS MIRACL Trust Project URL string (e.g., "https://example.miracl.io")
    static var projectURL: String {
        "https://\(projectDomain)"
    }
}
