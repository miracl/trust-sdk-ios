import Foundation

protocol CryptoBlueprint: Sendable {
    func clientPass1(
        mpinId: Data,
        token: Data,
        pinCode: Int32
    ) -> (u: Data, x: Data, s: Data, error: CryptoError?)

    func clientPass2(
        xValue: Data,
        yValue: Data,
        sValue: Data
    ) -> (Data, CryptoError?)

    func generateKeyPair() -> (privateKey: Data, publicKey: Data, error: CryptoError?)

    func getSigningClientToken(
        clientSecret1: Data,
        clientSecret2: Data,
        privateKey: Data,
        signingMpinId: Data,
        pinCode: Int32
    ) -> (Data, CryptoError?)

    func sign(
        message: Data,
        signingMpinId: Data,
        signingToken: Data,
        pinCode: Int32,
        timestamp: Int32
    ) -> (Data, Data, CryptoError?)
}
