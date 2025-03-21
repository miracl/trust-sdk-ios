@testable import MIRACLTrust
import XCTest

private class ExampleJSONObject: NSObject, Codable {
    var firstExampleProperty: String
    var secondExampleProperty: String
    var numberValue: Int
}

private enum APIRequestExecutorSampleError: Error {
    case unknownError
}

class APIRequestExecutorTests: XCTestCase {
    var requestExecutor: APIRequestExecutor?
    var mockSession = URLSessionMock()

    var exampleURL = URL(string: "https://www.example.com")!
    let example1 = "example1"
    let example2 = "example2"
    let randomNumber = 1
    let miraclLogger = MIRACLLogger(logger: DefaultLogger(level: .none))

    override func setUp() {
        mockSession = createMockURLSession()
        requestExecutor = APIRequestExecutor(
            urlSessionConfiguration: URLSessionConfiguration.default,
            miraclLogger: miraclLogger
        )
        requestExecutor?.urlSession = mockSession
    }

    func testExecutorSuccessfulRequest() throws {
        let requestExecutor = try XCTUnwrap(requestExecutor)
        let request = try XCTUnwrap(
            APIRequest(
                url: exampleURL,
                path: "examplePath",
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )
        )
        let example1 = example1
        let example2 = example2
        let randomNumber = randomNumber

        requestExecutor.execute(
            apiRequest: request
        ) { (callResult: APICallResult, exampleJSONObject: ExampleJSONObject?, error: Error?) in
            do {
                XCTAssertEqual(callResult, APICallResult.success)
                XCTAssertNil(error)

                let exampleObject = try XCTUnwrap(exampleJSONObject)
                XCTAssertEqual(exampleObject.firstExampleProperty, example1)
                XCTAssertEqual(exampleObject.secondExampleProperty, example2)
                XCTAssertEqual(exampleObject.numberValue, randomNumber)
            } catch {
                XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
            }
        }
    }

    func testExecutorFailWithServerError() throws {
        let requestExecutor = try XCTUnwrap(requestExecutor)

        let desiredStatusCode = 500
        let desiredError = APIError.apiServerError(statusCode: desiredStatusCode, message: nil, requestURL: URL(string: "https://www.example.com/examplePath"))
        mockSession.response = HTTPURLResponse(
            url: exampleURL,
            statusCode: desiredStatusCode,
            httpVersion: "",
            headerFields: nil
        )
        mockSession.data = nil

        let request = try XCTUnwrap(
            APIRequest(
                url: exampleURL,
                path: "examplePath",
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )
        )

        requestExecutor.execute(
            apiRequest: request
        ) { (apiCallResult: APICallResult, responseObject: ExampleJSONObject?, error: Error?) in
            XCTAssertEqual(apiCallResult, APICallResult.failed)
            XCTAssertNil(responseObject)

            assertError(current: error, expected: desiredError)
        }
    }

    func testExecutorFailWithClientErrorWithoutResponse() throws {
        let requestExecutor = try XCTUnwrap(requestExecutor)

        let desiredStatusCode = 401
        let desiredError = APIError.apiClientError(clientErrorData: nil, requestId: "", message: nil, requestURL: URL(string: "https://www.example.com/examplePath"))
        mockSession.response = HTTPURLResponse(
            url: exampleURL,
            statusCode: desiredStatusCode,
            httpVersion: "",
            headerFields: nil
        )
        mockSession.data = nil

        let request = try XCTUnwrap(
            APIRequest(
                url: exampleURL,
                path: "examplePath",
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )
        )

        requestExecutor.execute(
            apiRequest: request
        ) { (apiCallResult: APICallResult, responseObject: ExampleJSONObject?, error: Error?) in
            XCTAssertEqual(apiCallResult, APICallResult.failed)
            XCTAssertNil(responseObject)

            assertError(current: error, expected: desiredError)
        }
    }

    func testExecutorFailWithClientErrorWithResponse() throws {
        let requestExecutor = try XCTUnwrap(requestExecutor)

        let code = "INVALID_REQUEST_PARAMETERS"
        let info = "Missing or invalid parameters from the request."
        let backoffPeriod = "1680602131"
        let expectedRequestId = "q61veai83v4jujcr"

        let responseData = """
        {
           "requestID":"\(expectedRequestId)",
           "error":{
                "code":"\(code)",
                "info":"\(info)",
                "context" : { "backoff" : "\(backoffPeriod)" }
            }
        }
        """
        let desiredStatusCode = 401
        mockSession.response = HTTPURLResponse(
            url: exampleURL,
            statusCode: desiredStatusCode,
            httpVersion: "",
            headerFields: nil
        )
        mockSession.data = responseData.data(using: .utf8)

        let request = try XCTUnwrap(
            APIRequest(
                url: exampleURL,
                path: "examplePath",
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )
        )

        requestExecutor.execute(
            apiRequest: request
        ) { (apiCallResult: APICallResult, responseObject: ExampleJSONObject?, error: Error?) in
            XCTAssertEqual(apiCallResult, APICallResult.failed)
            XCTAssertNil(responseObject)

            XCTAssertNotNil(error)
            if let error {
                if case let APIError.apiClientError(clientErrorData: clientErrorData, requestId: requestId, message: _, requestURL: _) = error {
                    do {
                        let clientErrorData = try XCTUnwrap(clientErrorData)
                        XCTAssertEqual(clientErrorData.code, code)
                        XCTAssertEqual(clientErrorData.info, info)

                        let context = try XCTUnwrap(clientErrorData.context)
                        XCTAssertEqual(context["backoff"], backoffPeriod)

                        XCTAssertEqual(requestId, expectedRequestId)
                    } catch {
                        XCTFail("Error when unrwap clientErrorData")
                    }
                }
            } else {
                XCTFail("Error when unrwap error object")
            }
        }
    }

    func testExecutorFailWithClientErrorWithANewResponse() throws {
        let requestExecutor = try XCTUnwrap(requestExecutor)

        let code = "INVALID_REQUEST_PARAMETERS"
        let info = "Missing or invalid parameters from the request."
        let backoffPeriod = "1680602131"
        let expectedRequestId = "q61veai83v4jujcr"

        let responseData = """
        {
            "error":"\(code)",
            "info":"\(info)",
            "context" : { "requestID":"\(expectedRequestId)", "backoff" : "\(backoffPeriod)" }
        }
        """
        let desiredStatusCode = 401
        mockSession.response = HTTPURLResponse(
            url: exampleURL,
            statusCode: desiredStatusCode,
            httpVersion: "",
            headerFields: nil
        )
        mockSession.data = responseData.data(using: .utf8)

        let request = try XCTUnwrap(
            APIRequest(
                url: exampleURL,
                path: "examplePath",
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )
        )

        requestExecutor.execute(
            apiRequest: request
        ) { (apiCallResult: APICallResult, responseObject: ExampleJSONObject?, error: Error?) in
            XCTAssertEqual(apiCallResult, APICallResult.failed)
            XCTAssertNil(responseObject)

            XCTAssertNotNil(error)
            if let error {
                if case let APIError.apiClientError(clientErrorData: clientErrorData, requestId: requestId, message: _, requestURL: _) = error {
                    do {
                        let clientErrorData = try XCTUnwrap(clientErrorData)
                        XCTAssertEqual(clientErrorData.code, code)
                        XCTAssertEqual(clientErrorData.info, info)

                        let context = try XCTUnwrap(clientErrorData.context)
                        XCTAssertEqual(context["backoff"], backoffPeriod)

                        XCTAssertEqual(requestId, expectedRequestId)
                    } catch {
                        XCTFail("Error when unrwap clientErrorData")
                    }
                }
            } else {
                XCTFail("Error when unrwap error object")
            }
        }
    }

    func testExecutorFailWithClientErrorWithMissingErrorResponse() throws {
        let requestExecutor = try XCTUnwrap(requestExecutor)

        let responseData = """
        {
           "requestID":"q61veai83v4jujcr",
        }
        """

        let desiredStatusCode = 401
        let desiredError = APIError.apiClientError(clientErrorData: nil, requestId: "", message: responseData, requestURL: URL(string: "https://www.example.com/examplePath"))
        mockSession.response = HTTPURLResponse(
            url: exampleURL,
            statusCode: desiredStatusCode,
            httpVersion: "",
            headerFields: nil
        )
        mockSession.data = responseData.data(using: .utf8)

        let request = try XCTUnwrap(
            APIRequest(
                url: exampleURL,
                path: "examplePath",
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )
        )

        requestExecutor.execute(
            apiRequest: request
        ) { (apiCallResult: APICallResult, responseObject: ExampleJSONObject?, error: Error?) in
            XCTAssertEqual(apiCallResult, APICallResult.failed)
            XCTAssertNil(responseObject)

            assertError(current: error, expected: desiredError)
        }
    }

    func testExecutorUnknownErrorCode() throws {
        let requestExecutor = try XCTUnwrap(requestExecutor)

        let desiredStatusCode = 301
        let desiredError = APIError.apiServerError(statusCode: desiredStatusCode, message: nil, requestURL: URL(string: "https://www.example.com/examplePath"))
        mockSession.response = HTTPURLResponse(
            url: exampleURL,
            statusCode: desiredStatusCode,
            httpVersion: "",
            headerFields: nil
        )
        mockSession.data = nil

        let request = try XCTUnwrap(
            APIRequest(
                url: exampleURL,
                path: "examplePath",
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )
        )

        requestExecutor.execute(
            apiRequest: request
        ) { (apiCallResult: APICallResult, responseObject: ExampleJSONObject?, error: Error?) in
            XCTAssertEqual(apiCallResult, APICallResult.failed)
            XCTAssertNil(responseObject)

            assertError(current: error, expected: desiredError)
        }
    }

    func testExecutorNoData() throws {
        let desiredError = APIError.executionError("No data when request is succesful.", URL(string: "https://www.example.com/examplePath"))
        let requestExecutor = try XCTUnwrap(requestExecutor)

        mockSession.data = nil
        let request = try XCTUnwrap(
            APIRequest(
                url: exampleURL,
                path: "examplePath",
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )
        )

        requestExecutor.execute(apiRequest: request) { (apiCallResult: APICallResult, responseObject: ExampleJSONObject?, error: Error?) in
            XCTAssertEqual(apiCallResult, APICallResult.failed)
            XCTAssertNil(responseObject)

            assertError(
                current: error,
                expected: desiredError
            )
        }
    }

    func testExecutorEmptyData() throws {
        let requestExecutor = try XCTUnwrap(requestExecutor)
        let request = try XCTUnwrap(
            APIRequest(
                url: exampleURL,
                path: "examplePath",
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )
        )
        mockSession.data = Data()

        requestExecutor.execute(apiRequest: request) { (apiCallResult: APICallResult, responseObject: ExampleJSONObject?, error: Error?) in
            XCTAssertEqual(apiCallResult, APICallResult.success)
            XCTAssertNil(responseObject)
            XCTAssertNil(error)
        }
    }

    func testExecutorSessionError() throws {
        let desiredError = APIRequestExecutorSampleError.unknownError
        let requestExecutor = try XCTUnwrap(requestExecutor)

        mockSession.error = desiredError
        let request = try XCTUnwrap(
            APIRequest(
                url: exampleURL,
                path: "examplePath",
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )
        )

        requestExecutor.execute(apiRequest: request) { (apiCallResult: APICallResult, responseObject: ExampleJSONObject?, error: Error?) in
            XCTAssertEqual(apiCallResult, APICallResult.failed)
            XCTAssertNil(responseObject)

            assertError(
                current: error,
                expected: desiredError
            )
        }
    }

    func testExecutorMalformedJson() throws {
        let requestExecutor = try XCTUnwrap(requestExecutor)

        mockSession.error = nil
        mockSession.data = Data("""
            {
            "firstExampleProperty": "\(example1)",
            "secondExampleProperty": "\(example2)"
        """.utf8)

        let request = try XCTUnwrap(
            APIRequest(
                url: exampleURL,
                path: "examplePath",
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )
        )

        requestExecutor.execute(apiRequest: request) { (apiCallResult: APICallResult, responseObject: ExampleJSONObject?, error: Error?) in
            XCTAssertEqual(apiCallResult, APICallResult.failed)
            XCTAssertNil(responseObject)

            var isJsonError = false
            if let jsonError = error as? APIError,
               case APIError.apiMalformedJSON = jsonError {
                isJsonError = true
            }
            XCTAssertTrue(isJsonError)
        }
    }

    func testInvalidRequestBody() throws {
        let code = "INVALID_REQUEST_BODY"

        try testInvalidErrorCodes(code)
    }

    func testpushNotificationPlatformError() throws {
        let code = "PUSH_NOTIFICATION_PLATFORM_ERROR"

        try testInvalidErrorCodes(code)
    }

    func testCUVError() throws {
        let code = "CUV_ERROR"

        try testInvalidErrorCodes(code)
    }

    func testBackoffError() throws {
        let code = "BACKOFF_ERROR"

        try testInvalidErrorCodes(code)
    }

    func testProjectMismatch() throws {
        let code = "PROJECT_MISMATCH"
        try testInvalidErrorCodes(code)
    }

    func testInvalidAuthSession() throws {
        let code = "INVALID_AUTH_SESSION"

        try testInvalidErrorCodes(code)
    }

    func testQuickCodeLimited() throws {
        let code = "QUICKCODE_LIMITED"

        try testInvalidErrorCodes(code)
    }

    func testMpinIDExpired() throws {
        let code = "MPINID_EXPIRED"

        try testInvalidErrorCodes(code)
    }

    func testMpinIDRevoked() throws {
        let code = "MPINID_REVOKED"

        try testInvalidErrorCodes(code)
    }

    func testNoPushToken() throws {
        let code = "NO_PUSH_TOKEN"

        try testInvalidErrorCodes(code)
    }

    func testInvalidAuth() throws {
        let code = "INVALID_AUTH"

        try testInvalidErrorCodes(code)
    }

    func testInvalidActivationToken() throws {
        let code = "INVALID_ACTIVATION_TOKEN"
        try testInvalidErrorCodes(code)
    }

    // MARK: Private

    private func createMockURLSession() -> URLSessionMock {
        let mockSession = URLSessionMock()

        mockSession.response = HTTPURLResponse(
            url: exampleURL,
            statusCode: 200,
            httpVersion: "",
            headerFields: nil
        )
        mockSession.data = Data("""
            {
            "firstExampleProperty": "\(example1)",
            "secondExampleProperty": "\(example2)",
            "numberValue" : \(randomNumber)
            }
        """.utf8)

        mockSession.error = nil

        return mockSession
    }

    private func testInvalidErrorCodes(_ code: String) throws {
        let requestExecutor = try XCTUnwrap(requestExecutor)
        let expectedRequestId = "q61veai83v4jujcr"
        let info = UUID().uuidString

        let responseData = """
        {
           "requestID":"\(expectedRequestId)",
           "error":{
                "code":"\(code)",
                "info":"\(info)"
            }
        }
        """
        let desiredStatusCode = 401
        mockSession.response = HTTPURLResponse(
            url: exampleURL,
            statusCode: desiredStatusCode,
            httpVersion: "",
            headerFields: nil
        )
        mockSession.data = responseData.data(using: .utf8)

        let request = try XCTUnwrap(
            APIRequest(
                url: exampleURL,
                path: "examplePath",
                requestBody: EmptyRequestBody(),
                miraclLogger: miraclLogger
            )
        )

        requestExecutor.execute(
            apiRequest: request
        ) { (apiCallResult: APICallResult, responseObject: ExampleJSONObject?, error: Error?) in
            XCTAssertEqual(apiCallResult, APICallResult.failed)
            XCTAssertNil(responseObject)

            XCTAssertNotNil(error)
            if let error {
                if case let APIError.apiClientError(clientErrorData: clientErrorData, requestId: requestId, message: _, requestURL: _) = error {
                    do {
                        let clientErrorData = try XCTUnwrap(clientErrorData)
                        XCTAssertEqual(clientErrorData.code, code)
                        XCTAssertEqual(clientErrorData.info, info)

                        XCTAssertEqual(requestId, expectedRequestId)
                    } catch {
                        XCTFail("Error when unrwap clientErrorData")
                    }
                }
            } else {
                XCTFail("Error when unrwap error object")
            }
        }
    }
}
