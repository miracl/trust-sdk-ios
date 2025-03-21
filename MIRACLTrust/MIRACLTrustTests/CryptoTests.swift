@testable import MIRACLTrust
import XCTest

class CryptoTests: XCTestCase {
    let crypto = Crypto(miraclLogger: MIRACLLogger(logger: DefaultLogger(level: .none)))

    let mpinId = Data(hexString: "7b22696174223a313639333535333934322c22757365724944223a227261646f736c61762e70656e6576406d697261636c2e636f6d222c22634944223a2232663234633236312d306539652d343736332d393065612d343466386661666262363339222c2273616c74223a222f674956583656437432374a384a517a426f454f4151222c2276223a352c2273636f7065223a5b2261757468225d2c22647461223a5b5d2c227674223a227076227d")
    let token = Data(hexString: "04212d912f155aa1d55ad60a5538e87d928c330724cfbec94243c3dcb55e41d280190f7b6201ba24d01e16e0ddb8bd83cddb756578d74420812cccd8e659247509")
    let validY = "0f2226ba5d14134292cff31a4ca18b6de74965ff1837989ab5546e3b3e02d82f"

    let clientSecret1 = Data(hexString: "0417773fb20d315fd98c117a5a3287203102791c04679367da55d16868869cafcf1db1ec239097621d21edf5b9a874d06d6042b0d25c218cad40ed7486e3a36827")
    let clientSecret2 = Data(hexString: "04218c054d30d472198931fc44569b3ff305c27cf7e9de4bd59d439870ffcc6cd8124f8f7785bb1955d4dce73cfce5dba43e3f0c5c6f0868671adf64fc1675ff4f")

    let pinCode = Int32(8902)

    func testClientPass1() {
        let (u, x, s, error) = crypto.clientPass1(
            mpinId: mpinId,
            token: token,
            pinCode: pinCode
        )
        XCTAssertNotNil(u)
        XCTAssertNotNil(x)
        XCTAssertNotNil(s)
        XCTAssertNil(error)
    }

    func testClientPass1ForError() {
        let token = Data(hexString: "")

        let (u, x, s, error) = crypto.clientPass1(
            mpinId: mpinId,
            token: token,
            pinCode: pinCode
        )
        XCTAssertEqual(u, Data())
        XCTAssertEqual(x, Data())
        XCTAssertEqual(s, Data())
        assertError(current: error, expected: CryptoError.clientPass1Error(info: "Could not calculate pass 1 request data: -14"))
    }

    func testClientPass2() throws {
        let (_, x, s, _) = crypto.clientPass1(
            mpinId: mpinId,
            token: token,
            pinCode: pinCode
        )
        let y = Data(hexString: validY)

        let (result, clientPass2Error) = crypto.clientPass2(xValue: x, yValue: y, sValue: s)

        XCTAssertNil(clientPass2Error)
        let unwrappedResult = try XCTUnwrap(result)
        XCTAssertFalse(unwrappedResult.isEmpty)
    }

    func testClientPass2ForError() throws {
        let (_, x, _, _) = crypto.clientPass1(
            mpinId: mpinId,
            token: token,
            pinCode: pinCode
        )
        let y = Data(hexString: validY)

        let (result, clientPass2Error) = crypto.clientPass2(xValue: x, yValue: y, sValue: Data())

        XCTAssertEqual(result, Data())
        assertError(
            current: clientPass2Error, expected: CryptoError.clientPass2Error(info: "Could not calculate pass 2 request data: -14")
        )
    }

    func testGenerateKeypair() {
        let (privateKey, publicKey, error) = crypto.generateKeyPair()

        XCTAssertNotNil(publicKey)
        XCTAssertNotNil(privateKey)
        XCTAssertNil(error)
    }

    func testGetSigningClientToken() {
        let (privateKey, _, _) = crypto.generateKeyPair()

        let (token, error) = crypto.getSigningClientToken(
            clientSecret1: clientSecret1,
            clientSecret2: clientSecret2,
            privateKey: privateKey,
            signingMpinId: mpinId,
            pinCode: pinCode
        )

        XCTAssertNotNil(token)
        XCTAssertNil(error)
    }

    func testGetSigningClientTokenRecombineErrorEmptySecondSecret() {
        let (privateKey, _, _) = crypto.generateKeyPair()

        let clientSecret2 = Data(hexString: "")

        let (token, error) = crypto.getSigningClientToken(
            clientSecret1: clientSecret1,
            clientSecret2: clientSecret2,
            privateKey: privateKey,
            signingMpinId: mpinId,
            pinCode: pinCode
        )

        XCTAssertEqual(token, Data())
        assertError(
            current: error,
            expected: CryptoError.getSigningClientToken(info: "Could not combine the client secret shares: -14")
        )
    }

    func testGetSigningClientTokenRecombineErrorEmptyFirstSecret() {
        let (privateKey, _, _) = crypto.generateKeyPair()

        let clientSecret1 = Data(hexString: "")

        let (token, error) = crypto.getSigningClientToken(
            clientSecret1: clientSecret1,
            clientSecret2: clientSecret2,
            privateKey: privateKey,
            signingMpinId: mpinId,
            pinCode: pinCode
        )

        XCTAssertEqual(token, Data())
        assertError(
            current: error,
            expected: CryptoError.getSigningClientToken(info: "Could not combine the client secret shares: -14")
        )
    }

    func testSign() throws {
        let message = try XCTUnwrap(UUID().uuidString.data(using: .utf8))
        let timestamp = Int32(Date().timeIntervalSince1970)

        let (uData, vData, cryptoError) = crypto.sign(
            message: message,
            signingMpinId: mpinId,
            signingToken: token,
            pinCode: pinCode,
            timestamp: timestamp
        )

        XCTAssertNotNil(uData)
        XCTAssertNotNil(vData)
        XCTAssertNil(cryptoError)
    }

    func testSignError() throws {
        let message = try XCTUnwrap(UUID().uuidString.data(using: .utf8))
        let timestamp = Int32(Date().timeIntervalSince1970)

        let (uData, vData, cryptoError) = crypto.sign(
            message: message,
            signingMpinId: Data(),
            signingToken: Data(),
            pinCode: pinCode,
            timestamp: timestamp
        )

        XCTAssertEqual(uData, Data())
        XCTAssertEqual(vData, Data())
        assertError(current: cryptoError, expected: CryptoError.signError(info: "Could not sign message: -14"))
    }
}
