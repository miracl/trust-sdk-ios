@testable import MIRACLTrust
import XCTest

class APIRequestTests: XCTestCase {
    let exampleURL = URL(string: "https://example.com")!
    let miraclLogger = MIRACLLogger(logger: DefaultLogger(level: .none))

    func testGetRequestCreation() {
        let randomString = NSUUID().uuidString
        let queryParams = ["randomKey": "randomValue"]

        do {
            let miraclApiRequest = try APIRequest(
                url: exampleURL,
                path: "\(randomString)",
                queryParameters: queryParams,
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )

            if let urlRequest = miraclApiRequest.urlRequest() {
                XCTAssertNotNil(urlRequest.url)
                XCTAssertEqual(urlRequest.httpMethod, "GET")
                XCTAssertEqual(urlRequest.url!.host, exampleURL.host)
                XCTAssertEqual(urlRequest.url!.path, "/\(randomString)")
                XCTAssertNotNil(urlRequest.url!.query)
            }

        } catch {
            XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
        }
    }

    func testPostRequestCreation() {
        let randomString = NSUUID().uuidString

        do {
            let miraclApiRequest = try APIRequest(
                url: exampleURL,
                path: "/\(randomString)",
                method: .post,
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )

            if let urlRequest = miraclApiRequest.urlRequest() {
                XCTAssertNotNil(urlRequest.url)
                XCTAssertEqual(urlRequest.httpMethod, "POST")
                XCTAssertEqual(urlRequest.url!.host, exampleURL.host)
                XCTAssertEqual(urlRequest.url!.path, "/\(randomString)")
            }

        } catch {
            XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
        }
    }

    func testPUTRequestCreation() {
        let randomString = NSUUID().uuidString

        do {
            let miraclApiRequest = try APIRequest(
                url: exampleURL,
                path: "/\(randomString)",
                method: .put,
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )

            if let urlRequest = miraclApiRequest.urlRequest() {
                XCTAssertNotNil(urlRequest.url)
                XCTAssertEqual(urlRequest.httpMethod, "PUT")
                XCTAssertEqual(urlRequest.url!.host, exampleURL.host)
                XCTAssertEqual(urlRequest.url!.path, "/\(randomString)")
            }

        } catch {
            XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
        }
    }

    func testDeleteRequestCreation() {
        let randomString = NSUUID().uuidString

        do {
            let miraclApiRequest = try APIRequest(
                url: exampleURL,
                path: "/\(randomString)",
                method: .delete,
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )

            if let urlRequest = miraclApiRequest.urlRequest() {
                XCTAssertNotNil(urlRequest.url)
                XCTAssertEqual(urlRequest.httpMethod, "DELETE")
                XCTAssertEqual(urlRequest.url!.host, exampleURL.host)
                XCTAssertEqual(urlRequest.url!.path, "/\(randomString)")
            }

        } catch {
            XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
        }
    }

    func testInvalidURL() {
        let randomString = NSUUID().uuidString
        let notURL = URL(string: "Definitely not url!1!")

        XCTAssertThrowsError(try APIRequest(
            url: notURL,
            path: "\(randomString)",
            requestBody: EmptyRequestBody(),
            miraclLogger: miraclLogger
        )) { error in
            XCTAssertNotNil(error)
        }
    }

    func testInvalidURLWithSlashPath() {
        let randomString = NSUUID().uuidString
        let notURL = URL(string: "Definitely not url!1!")

        XCTAssertThrowsError(try APIRequest(
            url: notURL,
            path: "/\(randomString)",
            requestBody: EmptyRequestBody(),
            miraclLogger: miraclLogger
        )) { error in
            XCTAssertTrue(error is APIRequestError)
            XCTAssertEqual(error as? APIRequestError, APIRequestError.fail("Invalid URL Scheme"))
        }
    }

    func testPartiallyInvalidURL() {
        let randomString = NSUUID().uuidString
        var notURL = URL(string: "example.com")

        XCTAssertThrowsError(try APIRequest(
            url: notURL,
            path: "\(randomString)",
            requestBody: EmptyRequestBody(),
            miraclLogger: miraclLogger
        )) { error in
            XCTAssertTrue(error is APIRequestError)
            XCTAssertEqual(error as? APIRequestError, APIRequestError.fail("Invalid URL Scheme"))
        }

        notURL = URL(string: "https://")
        XCTAssertThrowsError(try APIRequest(
            url: notURL,
            path: "\(randomString)",
            requestBody: EmptyRequestBody(),
            miraclLogger: miraclLogger
        )) { error in
            XCTAssertTrue(error is APIRequestError)
            XCTAssertEqual(error as? APIRequestError, APIRequestError.fail("Invalid URL Host"))
        }
    }
}
