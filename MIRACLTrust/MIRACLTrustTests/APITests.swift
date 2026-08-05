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

    func testGetTAShare2ForError() throws {
        let desiredStatusCode = 400

        let taShareURL = try XCTUnwrap(URL(string: "https://www.tashare.com"))
        let desiredError = APIError.apiClientError(statusCode: desiredStatusCode, clientErrorData: nil, requestId: "", message: nil, requestURL: taShareURL)

        let api = try XCTUnwrap(api)

        mockURLSession.data = nil
        mockURLSession.error = nil
        mockURLSession.response = HTTPURLResponse(
            url: baseURL,
            statusCode: desiredStatusCode,
            httpVersion: "",
            headerFields: nil
        )

        api.getTAShare(
            designatedTA: DesignatedTA(url: taShareURL, token: UUID().uuidString),
            mpinId: UUID().uuidString,
            publicKey: UUID().uuidString
        ) { result, response, error in
            XCTAssertEqual(result, APICallResult.failed)
            XCTAssertNil(response)
            assertError(current: error, expected: desiredError)
        }
    }

    func testGetTAShare() throws {
        let taShareURL = try XCTUnwrap(URL(string: "https://www.tashare.com"))
        let api = try XCTUnwrap(api)
        let node = UUID().uuidString
        let share = UUID().uuidString

        mockURLSession.data = Data("""
            {
                "node": "\(node)",
                "share": "\(share)"
            }
        """.utf8)

        api.getTAShare(
            designatedTA: DesignatedTA(url: taShareURL, token: UUID().uuidString),
            mpinId: UUID().uuidString,
            publicKey: UUID().uuidString
        ) { result, response, error in
            XCTAssertEqual(result, APICallResult.success)
            XCTAssertNil(error)
            do {
                let response = try XCTUnwrap(response)
                XCTAssertEqual(response.node, node)
                XCTAssertEqual(response.share, share)
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) аnd error \(error)")
            }
        }
    }

    func testRegisterUser() throws {
        let randomString = UUID().uuidString
        let pinLength = 4
        let api = try XCTUnwrap(api)
        let secretUrls = ["example.com", "example.com"]

        let designatedTAsArray = secretUrls.map { secretUrl in
            """
            { "url" : "\(secretUrl)", "token" : "\(randomString)" }
            """
        }.joined(separator: ",")

        mockURLSession.data = Data(
            """
                {
                    "mpinId" : "\(randomString)",
                    "projectId" : "\(randomString)",
                    "pinLength" : \(pinLength),
                    "designatedTAs" : [ \(designatedTAsArray) ]
                }
            """.utf8
        )

        api.registerUser(
            userId: randomString,
            activationToken: randomString,
            deviceName: randomString,
            publicKey: randomString,
            pushToken: nil,
            deviceTag: randomString
        ) { result, response, error in
            do {
                let response = try XCTUnwrap(response)

                XCTAssertEqual(response.mpinId, randomString)
                XCTAssertEqual(response.projectId, randomString)
                let designatedTAs = response.designatedTAs
                for (index, designatedTA) in designatedTAs.enumerated() {
                    XCTAssertEqual(designatedTA.url, URL(string: secretUrls[index]))
                    XCTAssertEqual(designatedTA.token, randomString)
                }
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }

            XCTAssertNil(error)
            XCTAssertEqual(result, APICallResult.success)
        }
    }

    func testRegisterUserWithInvalidDesignatedTAURL() throws {
        let randomString = UUID().uuidString
        let pinLength = 4
        let api = try XCTUnwrap(api)
        let secretUrls = ["https:// example. com/my endpoint ", "example.com"]

        let designatedTAsArray = secretUrls.map { secretUrl in
            """
            { "url" : "\(secretUrl)", "token" : "\(randomString)" }
            """
        }.joined(separator: ",")

        mockURLSession.data = Data(
            """
                {
                    "mpinId" : "\(randomString)",
                    "projectId" : "\(randomString)",
                    "pinLength" : \(pinLength),
                    "designatedTAs" : [ \(designatedTAsArray) ]
                }
            """.utf8
        )

        api.registerUser(
            userId: randomString,
            activationToken: randomString,
            deviceName: randomString,
            publicKey: randomString,
            pushToken: nil,
            deviceTag: randomString
        ) { result, response, error in
            XCTAssertNil(response)
            XCTAssertNotNil(error)
            XCTAssertEqual(result, APICallResult.failed)
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
