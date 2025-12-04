import JWTKit

struct SignatureCertificateJWTPayload: JWTPayload {
    var cAt: IssuedAtClaim
    var exp: ExpirationClaim
    var hash: String

    func verify(using _: JWTKit.JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}
