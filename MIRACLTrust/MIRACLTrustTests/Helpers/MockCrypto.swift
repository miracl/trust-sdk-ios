@testable import MIRACLTrust

struct MockCrypto: CryptoBlueprint {
    var clientTokenData: Data = .init()
    var clientTokenError: CryptoError?

    var clientPass1U: Data = .init()
    var clientPass1X: Data = .init()
    var clientPass1S: Data = .init()
    var clientPass1Error: CryptoError?

    var clientPass2V: Data = .init()
    var clientPass2Error: CryptoError?

    var privateKey: Data = .init()
    var publicKey: Data = .init()
    var keyPairError: CryptoError?

    var signingClientToken: Data = .init()
    var signingClientTokenError: CryptoError?

    var signMessageU: Data = .init()
    var signMessageV: Data = .init()
    var signError: CryptoError?

    func clientPass1(mpinId _: Data, token _: Data, pinCode _: Int32) -> (u: Data, x: Data, s: Data, error: CryptoError?) {
        (clientPass1U, clientPass1X, clientPass1S, clientPass1Error)
    }

    func clientPass2(xValue _: Data, yValue _: Data, sValue _: Data) -> (Data, CryptoError?) {
        (clientPass2V, clientPass2Error)
    }

    func generateKeyPair() -> (privateKey: Data, publicKey: Data, error: CryptoError?) {
        (privateKey, publicKey, keyPairError)
    }

    func getSigningClientToken(clientSecret1 _: Data, clientSecret2 _: Data, privateKey _: Data, signingMpinId _: Data, pinCode _: Int32) -> (Data, CryptoError?) {
        (signingClientToken, signingClientTokenError)
    }

    func sign(message _: Data, signingMpinId _: Data, signingToken _: Data, pinCode _: Int32, timestamp _: Int32) -> (Data, Data, CryptoError?) {
        (signMessageU, signMessageV, signError)
    }
}
