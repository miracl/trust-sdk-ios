import MIRACLTrust

struct VerificationRequestBody: Codable {
    var projectId: String = ""
    var userId: String = ""
    var accessId: String?
    var expiration: Int?
    var delivery: String = "no"
}

struct HelperAPIVerificationResponse: Codable {
    var verificationURL: URL
}

struct ActivationTokenRequestBody: Codable {
    var userID: String = ""
}

struct VerifyJWTSignatureRequestBody: Codable {
    var token: String
}

struct VerifySigningRequestBody: Codable {
    var signature: Signature
    var timestamp: Int32
    var type = "verification"
}

struct Session: Codable {
    var qrURL: URL
}

struct SessionRequestBody: Codable {
    var projectId: String
    var userId: String?
}

struct EmptyRequestBody: Codable {}

struct EmptyResponse: Codable {}

@objc public final class SigningSession: NSObject, Sendable {
    public let qrURL: String

    public init(qrURL: String) {
        self.qrURL = qrURL
    }
}

struct SigningSessionResponse: Codable {
    var qrURL: String
}

struct SigningSessionRequestBody: Codable {
    var projectID: String
    var userID: String
    var hash: String
    var description: String
}
