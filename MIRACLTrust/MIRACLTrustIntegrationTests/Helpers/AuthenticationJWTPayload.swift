import JWTKit

struct AuthenticationJWTPayload: JWTPayload {
    var aud: AudienceClaim
    var sub: SubjectClaim
    var exp: ExpirationClaim

    func verify(using _: JWTKit.JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}
