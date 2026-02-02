@testable import MIRACLTrust
import XCTest

class APITests: XCTestCase {
    var baseURL = URL(string: "https://api.mpin.io")!
    var mockURLSession = URLSessionMock()
    var api: API?
    let logger = DefaultLogger(level: .none)

    override func setUpWithError() throws {
        mockURLSession = createMockSession()

        api = API(
            baseURL: baseURL,
            urlSessionConfiguration: URLSessionConfiguration.default,
            logger: logger
        )
        api?.executor.urlSession = mockURLSession
    }

    func testGetClientSecret2ForError() throws {
        let desiredStatusCode = 400

        let clientSecretURL = try XCTUnwrap(URL(string: "https://www.clientsecret.com"))
        let desiredError = APIError.apiClientError(statusCode: desiredStatusCode, clientErrorData: nil, requestId: "", message: nil, requestURL: clientSecretURL)

        let api = try XCTUnwrap(api)

        mockURLSession.data = nil
        mockURLSession.error = nil
        mockURLSession.response = HTTPURLResponse(
            url: baseURL,
            statusCode: desiredStatusCode,
            httpVersion: "",
            headerFields: nil
        )

        api.getClientSecretShare(clientSecretURL, completionHandler: { result, response, error in
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

        api.getClientSecretShare(clientSecretURL) { result, response, error in
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

    func testRegisterUser() throws {
        let randomString = UUID().uuidString
        let pinLength = 4
        let api = try XCTUnwrap(api)
        let curve = "BN254CX"
        let secretUrls = ["example.com", "example.com"]

        let secretUrlsString = secretUrls.map { secretUrl in
            "\"\(secretUrl)\""
        }.joined(separator: ",")

        mockURLSession.data = Data(
            """
                {
                    "mpinId" : "\(randomString)",
                    "projectId" : "\(randomString)",
                    "dtas" : "\(randomString)",
                    "curve" : "\(curve)",
                    "pinLength" : \(pinLength),
                    "secretUrls" : [ \(secretUrlsString)],
                    "verificationType" : "PV"
                }
            """.utf8
        )

        api.registerUser(
            userId: randomString,
            activationToken: randomString,
            deviceName: randomString,
            publicKey: randomString,
            pushToken: nil
        ) { result, response, error in
            do {
                let response = try XCTUnwrap(response)

                XCTAssertEqual(response.mpinId, randomString)
                XCTAssertEqual(response.projectId, randomString)
                XCTAssertEqual(response.dtas, randomString)
                XCTAssertEqual(response.curve, curve)
                XCTAssertEqual(response.secretUrls, secretUrls)
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
