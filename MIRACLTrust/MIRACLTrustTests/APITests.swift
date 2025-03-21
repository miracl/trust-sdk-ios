@testable import MIRACLTrust
import XCTest

class APITests: XCTestCase {
    var baseURL = URL(string: "https://api.mpin.io")!
    var mockURLSession = URLSessionMock()
    var api: API?
    let miraclLogger = MIRACLLogger(logger: DefaultLogger(level: .none))

    override func setUpWithError() throws {
        mockURLSession = createMockSession()

        api = API(
            baseURL: baseURL,
            urlSessionConfiguration: URLSessionConfiguration.default,
            miraclLogger: miraclLogger
        )
        api?.executor.urlSession = mockURLSession
    }

    func testGetClientSecret2ForError() throws {
        let desiredStatusCode = 400

        let clientSecretURL = try XCTUnwrap(URL(string: "https://www.clientsecret.com"))
        let desiredError = APIError.apiClientError(clientErrorData: nil, requestId: "", message: nil, requestURL: clientSecretURL)

        let api = try XCTUnwrap(api)

        mockURLSession.data = nil
        mockURLSession.error = nil
        mockURLSession.response = HTTPURLResponse(
            url: baseURL,
            statusCode: desiredStatusCode,
            httpVersion: "",
            headerFields: nil
        )

        api.getClientSecret2(for: clientSecretURL, completionHandler: { result, response, error in
            XCTAssertEqual(result, APICallResult.failed)
            XCTAssertNil(response)
            assertError(current: error, expected: desiredError)
        })
    }

    func testGetClientSecret2() throws {
        let clientSecretURL = try XCTUnwrap(URL(string: "https://www.clientsecret.com"))
        let api = try XCTUnwrap(api)
        let clientSecret = UUID().uuidString

        mockURLSession.data = Data("""
            { "dvsClientSecret": "\(clientSecret)" }
        """.utf8)

        api.getClientSecret2(for: clientSecretURL) { result, response, error in
            XCTAssertEqual(result, APICallResult.success)
            XCTAssertNil(error)
            do {
                let response = try XCTUnwrap(response)
                XCTAssertEqual(response.dvsClientSecret, clientSecret)
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) аnd error \(error)")
            }
        }
    }

    func testSignature() throws {
        let randomString = UUID().uuidString

        let api = try XCTUnwrap(api)
        let mpinId = randomString
        let regOTT = randomString

        mockURLSession.data = Data("""
            {
            "dvsClientSecretShare" : "\(randomString)",
            "cs2url" : "\(baseURL.absoluteString)",
            "curve"  : "\(randomString)",
            "dtas"   : "\(randomString)"
            }
        """.utf8)

        let baseURL = baseURL
        api.signature(for: mpinId, regOTT: regOTT, publicKey: UUID().uuidString) { result, response, error in
            do {
                let response = try XCTUnwrap(response)
                XCTAssertEqual(response.dvsClientSecretShare, randomString)
                XCTAssertEqual(response.curve, randomString)
                XCTAssertEqual(response.dtas, randomString)
                XCTAssertEqual(response.cs2URL!, baseURL)
            } catch {
                XCTFail("Fail at \(#function) on row \(#line), error \(error)")
            }

            XCTAssertNil(error)
            XCTAssertEqual(result, APICallResult.success)
        }
    }

    func testRegisterUser() throws {
        let randomString = UUID().uuidString
        let pinLength = 4
        let api = try XCTUnwrap(api)

        mockURLSession.data = Data("""
            {
            "mpinId" : "\(randomString)",
            "regOTT": "\(randomString)",
            "pinLength": \(pinLength) ,
            "projectId": "\(randomString)"
            }
        """.utf8)

        api.registerUser(
            for: randomString,
            deviceName: randomString,
            activationToken: randomString,
            pushToken: nil
        ) { result, response, error in
            do {
                let response = try XCTUnwrap(response)
                XCTAssertEqual(response.mpinId, randomString)
                XCTAssertEqual(response.regOTT, randomString)
                XCTAssertEqual(response.projectId, randomString)
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }

            XCTAssertNil(error)
            XCTAssertEqual(result, APICallResult.success)
        }
    }

    func testPass1() throws {
        let randomString = UUID().uuidString

        mockURLSession.data = Data("""
            { "y": "\(randomString)" }
        """.utf8)

        let api = try XCTUnwrap(api)
        api.pass1(
            for: randomString,
            mpinId: randomString,
            publicKey: nil,
            uValue: randomString,
            scope: ["oidc"]
        ) { result, response, error in
            do {
                let response = try XCTUnwrap(response)
                XCTAssertEqual(response.challenge, randomString)
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }

            XCTAssertNil(error)
            XCTAssertEqual(result, APICallResult.success)
        }
    }

    func testPass2() throws {
        let randomString = UUID().uuidString

        mockURLSession.data = Data("""
            { "authOTT": "\(randomString)" }
        """.utf8)

        let api = try XCTUnwrap(api)
        api.pass2(
            for: randomString,
            accessId: randomString,
            vValue: randomString
        ) { result, response, error in
            do {
                let response = try XCTUnwrap(response)
                XCTAssertEqual(response.authOTT, randomString)
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }

            XCTAssertNil(error)
            XCTAssertEqual(result, APICallResult.success)
        }
    }

    func testAuthenticate() throws {
        let randomString = UUID().uuidString

        mockURLSession.data = Data("""
            {  }
        """.utf8)

        let api = try XCTUnwrap(api)
        api.authenticate(authOTT: randomString) { result, response, error in
            XCTAssertNotNil(response)
            XCTAssertEqual(result, APICallResult.success)
            XCTAssertNil(error)
        }
    }

    // MARK: Private

    private func createMockSession() -> URLSessionMock {
        let mock = URLSessionMock()

        mock.error = nil
        mock.data = Data("""
          {
               "signatureURL": "https://api.mpin.io/rps/v2/signature",
               "registerURL": "https://api.mpin.io/rps/v2/user",
               "authenticateURL": "https://api.mpin.io/rps/v2/authenticate",
               "pass1URL": "https://api.mpin.io/rps/v2/pass1",
               "pass2URL": "https://api.mpin.io/rps/v2/pass2"
           }
        """.utf8)
        mock.response = HTTPURLResponse(
            url: baseURL,
            statusCode: 200,
            httpVersion: "",
            headerFields: nil
        )

        return mock
    }
}
