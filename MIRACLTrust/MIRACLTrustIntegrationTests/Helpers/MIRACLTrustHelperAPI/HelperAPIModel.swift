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
}

struct VerifySigningResponse: Codable {
    var certificate: String
}

struct StartSessionResponse: Codable {
    var qrURL: URL
    var webOTT: String
}

struct SessionStatusRequestBody: Codable {
    var webOTT: String
}

public struct SessionStatusResponse: Codable, Sendable {
    var status: String
    var signature: String
}

@objcMembers
@objc public final class StartSessionResult: NSObject, Codable, Sendable {
    public let accessId: String
    public let webOTT: String

    init(accessId: String, webOTT: String) {
        self.accessId = accessId
        self.webOTT = webOTT
    }
}

struct SessionRequestBody: Codable {
    var projectId: String
    var userId: String?
    var hash: String?
    var description: String?
}

struct EmptyRequestBody: Codable {}

struct EmptyResponse: Codable {}
