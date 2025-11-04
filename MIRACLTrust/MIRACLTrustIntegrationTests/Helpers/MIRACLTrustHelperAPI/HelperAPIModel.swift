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

struct StartSessionResponse: Codable {
    var qrURL: URL
    var webOTT: String
}

struct SessionStatusRequestBody: Codable {
    var webOTT: String
}

public struct SessionStatusResponse: Codable {
    var status: String
    var signature: String
}

@objcMembers
@objc public class StartSessionResult: NSObject, Codable {
    public var accessId: String
    public var webOTT: String

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
