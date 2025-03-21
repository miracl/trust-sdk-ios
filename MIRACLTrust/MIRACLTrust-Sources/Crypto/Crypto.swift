#if SWIFT_PACKAGE
    import CryptoSPM
#else
    import MIRACLTrust.Crypto
#endif

import Foundation

enum CryptoSupportedEllipticCurves: String {
    case BN254CX
}

/// Object - Oriented wrapper for AMCL crypto library.
struct Crypto: CryptoBlueprint, Sendable {
    private let mPinHashTypeBN254CX = Int32(32)
    private let defaultOctetSize = 65
    private let xOctetSize = 32
    private let randSeedSize = 256
    private let publicKeySize = 128

    private let miraclLogger: MIRACLLogger

    init(miraclLogger: MIRACLLogger) {
        self.miraclLogger = miraclLogger
    }

    func clientPass1(
        mpinId: Data,
        token: Data,
        pinCode: Int32
    ) -> (u: Data, x: Data, s: Data, error: CryptoError?) {
        logOperationStarted()

        let tokenOctet = octetFromData(data: mpinId)
        let tOctet = octetFromData(data: token)

        let xOctet = newOctet(withSize: xOctetSize)
        let sOctet = newOctet()
        let uOctet = newOctet()
        let utOctet = newOctet()
        let tpOctet = newOctet()

        let result = MPIN_BN254CX_CLIENT_1(mPinHashTypeBN254CX,
                                           0,
                                           tokenOctet,
                                           randomNumberGenerator(),
                                           xOctet,
                                           pinCode,
                                           tOctet,
                                           sOctet,
                                           uOctet,
                                           utOctet,
                                           tpOctet)

        guard result == 0 else {
            return (Data(), Data(), Data(), .clientPass1Error(info: "Could not calculate pass 1 request data: \(result)"))
        }

        let uBytes = dataFromOctet(octet: uOctet)
        let xBytes = dataFromOctet(octet: xOctet)
        let sBytes = dataFromOctet(octet: sOctet)

        logOperationFinished()

        return (uBytes, xBytes, sBytes, nil)
    }

    func clientPass2(xValue: Data, yValue: Data, sValue: Data) -> (Data, CryptoError?) {
        logOperationStarted()

        let xOctet = octetFromData(data: xValue)
        let yOctet = octetFromData(data: yValue)
        let vOctet = octetFromData(data: sValue)

        let result = MPIN_BN254CX_CLIENT_2(xOctet, yOctet, vOctet)

        logOperationFinished()

        guard result == 0 else {
            return (Data(), .clientPass2Error(info: "Could not calculate pass 2 request data: \(result)"))
        }

        let vBytes = dataFromOctet(octet: vOctet)

        return (vBytes, nil)
    }

    func generateKeyPair() -> (privateKey: Data, publicKey: Data, error: CryptoError?) {
        logOperationStarted()

        let privateKeyOctet = newOctet()
        let publicKeyOctet = newOctet(withSize: publicKeySize)

        let result = MPIN_BN254CX_GET_DVS_KEYPAIR(
            randomNumberGenerator(),
            privateKeyOctet,
            publicKeyOctet
        )

        logOperationFinished()

        guard result == 0 else {
            return (Data(), Data(), .generateSigningKeypairError(info: "Could not generate key pair: \(result)"))
        }

        let privateKeyData = dataFromOctet(octet: privateKeyOctet)
        let publicKeyData = dataFromOctet(octet: publicKeyOctet)

        return (privateKeyData, publicKeyData, nil)
    }

    func getSigningClientToken(
        clientSecret1: Data,
        clientSecret2: Data,
        privateKey: Data,
        signingMpinId: Data,
        pinCode: Int32
    ) -> (Data, CryptoError?) {
        logOperationStarted()

        let clientSecret1Octet = octetFromData(data: clientSecret1)
        let clientSecret2Octet = octetFromData(data: clientSecret2)

        let clientSecretOctet = newOctet()
        var result = MPIN_BN254CX_RECOMBINE_G1(
            clientSecret1Octet,
            clientSecret2Octet,
            clientSecretOctet
        )

        guard result == 0 else {
            return (Data(), .getSigningClientToken(info: "Could not combine the client secret shares: \(result)"))
        }

        let privateKeyOctet = octetFromData(data: privateKey)
        result = MPIN_BN254CX_GET_G1_MULTIPLE(nil,
                                              0,
                                              privateKeyOctet,
                                              clientSecretOctet,
                                              clientSecretOctet)

        guard result == 0 else {
            return (
                Data(),
                .getSigningClientToken(info: "Could not combine private key with client secret: \(result)")
            )
        }

        let mpinIdOctet = octetFromData(data: signingMpinId)
        result = MPIN_BN254CX_EXTRACT_PIN(mPinHashTypeBN254CX,
                                          mpinIdOctet,
                                          pinCode,
                                          clientSecretOctet)
        logOperationFinished()

        guard result == 0 else {
            return (Data(), .getSigningClientToken(info: "Could not extract PIN from client secret: \(result)"))
        }

        let tokenData = dataFromOctet(octet: clientSecretOctet)
        return (tokenData, nil)
    }

    public func sign(message: Data,
                     signingMpinId: Data,
                     signingToken: Data,
                     pinCode: Int32,
                     timestamp: Int32) -> (Data, Data, CryptoError?) {
        logOperationStarted()

        let rng = randomNumberGenerator()
        let signingMpinIdOctet = octetFromData(data: signingMpinId)
        let signingTokenOctet = octetFromData(data: signingToken)
        let xOctet = newOctet()
        let vOctet = newOctet()
        let uOctet = newOctet()
        let utOctet = newOctet()
        let tpOctet = newOctet()
        let messageOctet = octetFromData(data: message)
        let yOctet = newOctet()

        let result = MPIN_BN254CX_CLIENT(
            SHA256,
            0,
            signingMpinIdOctet,
            rng,
            xOctet,
            pinCode,
            signingTokenOctet,
            vOctet,
            uOctet,
            utOctet,
            tpOctet,
            messageOctet,
            timestamp,
            yOctet
        )

        logOperationFinished()

        if result != 0 {
            return (Data(), Data(), .signError(info: "Could not sign message: \(result)"))
        }

        let uData = dataFromOctet(octet: uOctet)
        let vData = dataFromOctet(octet: vOctet)

        return (uData, vData, nil)
    }

    // MARK: Private

    private func randomNumberGenerator() -> UnsafeMutablePointer<csprng> {
        let randomNumArray = (0 ..< randSeedSize).map { _ in
            Int8.random(in: 0 ..< Int8.max)
        }

        let randomNumbersPointer = UnsafeMutablePointer<Int8>.allocate(capacity: randSeedSize)
        randomNumbersPointer.initialize(from: randomNumArray, count: randomNumArray.count)

        let rng = UnsafeMutablePointer<csprng>.allocate(capacity: 1)
        RAND_seed(rng, Int32(randSeedSize), randomNumbersPointer)

        return rng
    }

    private func newOctet() -> UnsafeMutablePointer<octet> {
        newOctet(withSize: defaultOctetSize)
    }

    private func newOctet(withSize size: Int) -> UnsafeMutablePointer<octet> {
        let newOctet = UnsafeMutablePointer<octet>.allocate(capacity: 1)

        newOctet.pointee.len = Int32(size)
        newOctet.pointee.max = Int32(size)
        newOctet.pointee.val = UnsafeMutablePointer<Int8>.allocate(capacity: size)

        return newOctet
    }

    private func octetFromData(data: Data) -> UnsafeMutablePointer<octet> {
        let array = [UInt8](data).map {
            Int8(bitPattern: $0)
        }

        let byteArrayPointer = UnsafeMutablePointer<Int8>.allocate(capacity: array.count)
        byteArrayPointer.initialize(from: array, count: array.count)

        let byteArrayOctet = UnsafeMutablePointer<octet>.allocate(capacity: 1)
        byteArrayOctet.pointee.len = Int32(array.count)
        byteArrayOctet.pointee.max = Int32(array.count)
        byteArrayOctet.pointee.val = byteArrayPointer

        return byteArrayOctet
    }

    private func dataFromOctet(octet: UnsafeMutablePointer<octet>) -> Data {
        let buffer = UnsafeMutableBufferPointer(start: octet.pointee.val,
                                                count: Int(octet.pointee.len))
        return Data(buffer: buffer)
    }

    private func logOperationStarted(operationSignature: String = #function) {
        miraclLogger.debug(
            message: "`\(operationSignature)` operation started.",
            category: .crypto
        )
    }

    private func logOperationFinished(operationSignature: String = #function) {
        miraclLogger.debug(
            message: "`\(operationSignature)` operation finished.",
            category: .crypto
        )
    }
}
