@testable import MIRACLTrust
import XCTest

class VerificationConfirmationHandlerTest: XCTestCase {
    var verificationURL = URL(string: "https://api.mpin.io")!
    var mockAPI = MockAPI()
    var verificationConfirmationResponse = VerificationConfirmationResponse()
    var randomString = UUID().uuidString
    var expiryDate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())
    var userId = "int@miracl.com"
    var clientId = "hhstkihj1mgtq"
    var activationCode = "600d968cd4c968e08c32a12ee68a8cc9"
    var redirectURI = "https://example.com"

    override func setUpWithError() throws {
        try super.setUpWithError()

        verificationURL = URL(string: "https://api.mpin.io/verification/confirmation?client_id=\(clientId)&code=\(activationCode)&redirect_uri=\(redirectURI)&stage=auth&user_id=\(userId)")!

        verificationConfirmationResponse = VerificationConfirmationResponse()
        verificationConfirmationResponse.accessId = randomString
        verificationConfirmationResponse.actToken = randomString
        verificationConfirmationResponse.projectId = randomString

        mockAPI = MockAPI()
        mockAPI.verificationConfirmationResultCall = .success
        mockAPI.verificationConfirmationError = nil
        mockAPI.verificationConfirmationResponse = verificationConfirmationResponse
    }

    func testVerificationConfirmationHandler() throws {
        let randomStringCopy = randomString
        let userIdCopy = userId

        try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { activationTokenResponse, error in
            XCTAssertNil(error)

            XCTAssertNotNil(activationTokenResponse)
            do {
                let activationToken = try XCTUnwrap(activationTokenResponse?.activationToken)
                XCTAssertEqual(activationToken, randomStringCopy)
            } catch {
                XCTFail("Cannot unwrap activation token - \(error)")
            }

            XCTAssertNotNil(activationTokenResponse?.userId)
            XCTAssertEqual(userIdCopy, activationTokenResponse?.userId)

            XCTAssertNotNil(activationTokenResponse?.accessId)
            XCTAssertEqual(randomStringCopy, activationTokenResponse?.accessId)

            XCTAssertNotNil(activationTokenResponse?.projectId)
            XCTAssertEqual(randomStringCopy, activationTokenResponse?.projectId)
        })
    }

    func testEmptyActivationCode() throws {
        activationCode = ""
        verificationURL = URL(string: "https://api.mpin.io/verification/confirmation?client_id=\(clientId)&code=\(activationCode)&redirect_uri=\(redirectURI)&stage=auth&user_id=\(userId)")!

        XCTAssertThrowsError(try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { _, _ in }), "") { error in
            assertError(current: error, expected: ActivationTokenError.emptyVerificationCode)
        }
    }

    func testMissingActivationCode() throws {
        verificationURL = URL(string: "https://api.mpin.io/verification/confirmation?client_id=\(clientId)&redirect_uri=\(redirectURI)&stage=auth&user_id=\(userId)")!
        XCTAssertThrowsError(try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { _, _ in }), "") { error in
            assertError(current: error, expected: ActivationTokenError.emptyVerificationCode)
        }
    }

    func testInvalidUserId() throws {
        userId = ""
        verificationURL = URL(string: "https://api.mpin.io/verification/confirmation?client_id=\(clientId)&code=\(activationCode)&redirect_uri=\(redirectURI)&stage=auth&user_id=\(userId)")!

        XCTAssertThrowsError(try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { _, _ in }), "") { error in
            assertError(current: error, expected: ActivationTokenError.emptyUserId)
        }
    }

    func testMissingUserId() throws {
        verificationURL = URL(string: "https://api.mpin.io/verification/confirmation?client_id=\(clientId)&code=\(activationCode)&redirect_uri=\(redirectURI)&stage=auth")!

        XCTAssertThrowsError(try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { _, _ in }), "") { error in
            assertError(current: error, expected: ActivationTokenError.emptyUserId)
        }
    }

    func testFailedRequest() throws {
        let cause = APIError.apiServerError(statusCode: 403, message: nil, requestURL: nil)
        mockAPI.verificationConfirmationResultCall = .failed
        mockAPI.verificationConfirmationError = cause

        let desiredError = ActivationTokenError.getActivationTokenFail(cause)

        try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { activationTokenResponse, error in
            XCTAssertNil(activationTokenResponse)

            assertError(current: error, expected: desiredError)
        })
    }

    func testNilResponse() throws {
        mockAPI.verificationConfirmationResponse = nil

        try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { activationTokenResponse, error in
            XCTAssertNil(activationTokenResponse)
            assertError(current: error, expected: ActivationTokenError.getActivationTokenFail(nil))
        })
    }

    func testVerificationConfirmationErrorWithEmptyProjectId() throws {
        let accessId = UUID().uuidString
        let errorMessage = UUID().uuidString

        let badStatusResponse = """
        {
            "projectId":"",
            "accessId":"\(accessId)",
            "error":"\(errorMessage)"
        }
        """

        let cause = APIError.apiServerError(statusCode: 401, message: badStatusResponse, requestURL: nil)
        mockAPI.verificationConfirmationError = cause
        mockAPI.verificationConfirmationResponse = nil
        mockAPI.verificationConfirmationResultCall = .failed

        let expectedError = ActivationTokenError.getActivationTokenFail(cause)

        try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { activationTokenResponse, error in
            XCTAssertNil(activationTokenResponse)
            assertError(current: error, expected: expectedError)
        })
    }

    func testVerificationConfirmationErrorWithoutResponse() throws {
        let cause = APIError.apiServerError(statusCode: 401, message: "", requestURL: nil)
        mockAPI.verificationConfirmationError = cause
        mockAPI.verificationConfirmationResponse = nil
        mockAPI.verificationConfirmationResultCall = .failed

        let desiredError = ActivationTokenError.getActivationTokenFail(cause)

        try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { activationTokenResponse, error in
            XCTAssertNil(activationTokenResponse)
            assertError(current: error, expected: desiredError)
        })
    }

    func testVerificationConfirmationErrorWithInvalidVerificationCode() throws {
        let projectId = UUID().uuidString
        let accessId = UUID().uuidString

        let cause = apiClientError(
            with: UNSUCCESSFUL_VERIFICATION,
            context: [
                "projectId": projectId,
                "accessId": accessId
            ]
        )

        mockAPI.verificationConfirmationError = cause

        mockAPI.verificationConfirmationResponse = nil
        mockAPI.verificationConfirmationResultCall = .failed
        let userIdCopy = userId

        try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { activationTokenResponse, error in
            XCTAssertNil(activationTokenResponse)

            if let activationTokenError = error as? ActivationTokenError {
                if case let ActivationTokenError.unsuccessfulVerification(activationTokenErrorResponse: activationTokenErrorResponse) = activationTokenError, let activationTokenErrorResponse {
                    XCTAssertEqual(activationTokenErrorResponse.projectId, projectId)
                    XCTAssertEqual(activationTokenErrorResponse.accessId, accessId)
                    XCTAssertEqual(activationTokenErrorResponse.userId, userIdCopy)

                } else {
                    XCTFail("Error is no invalidVerificationCode")
                }
            } else {
                XCTFail("Error is no ActivationTokenError")
            }

        })
    }

    func testVerificationConfirmationErrorWithResponse() throws {
        let projectId = UUID().uuidString
        let accessId = UUID().uuidString

        let cause = apiClientError(
            with: INVALID_VERIFICATION_CODE,
            context: [
                "projectId": projectId,
                "accessId": accessId
            ]
        )

        mockAPI.verificationConfirmationError = cause
        mockAPI.verificationConfirmationResponse = nil
        mockAPI.verificationConfirmationResultCall = .failed
        let userIdCopy = userId

        try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { activationTokenResponse, error in
            XCTAssertNil(activationTokenResponse)

            if let activationTokenError = error as? ActivationTokenError {
                if case let ActivationTokenError.unsuccessfulVerification(activationTokenErrorResponse: activationTokenErrorResponse) = activationTokenError, let activationTokenErrorResponse {
                    XCTAssertEqual(activationTokenErrorResponse.projectId, projectId)
                    XCTAssertEqual(activationTokenErrorResponse.accessId, accessId)
                    XCTAssertEqual(activationTokenErrorResponse.userId, userIdCopy)

                } else {
                    XCTFail("Error is no invalidVerificationCode")
                }
            } else {
                XCTFail("Error is no ActivationTokenError")
            }

        })
    }

    func testVerificationConfirmationErrorWithoutErrorResponse() throws {
        let projectId = UUID().uuidString
        let accessId = UUID().uuidString

        let cause = apiClientError(
            with: INVALID_VERIFICATION_CODE,
            context: [
                "randomKey": projectId,
                "accessId": accessId
            ]
        )

        mockAPI.verificationConfirmationError = cause
        mockAPI.verificationConfirmationResponse = nil
        mockAPI.verificationConfirmationResultCall = .failed

        try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { activationTokenResponse, error in
            XCTAssertNil(activationTokenResponse)

            if let activationTokenError = error as? ActivationTokenError {
                if case let ActivationTokenError.unsuccessfulVerification(activationTokenErrorResponse: activationTokenErrorResponse) = activationTokenError {
                    XCTAssertNil(activationTokenErrorResponse)
                } else {
                    XCTFail("Error is no invalidVerificationCode")
                }
            } else {
                XCTFail("Error is no ActivationTokenError")
            }

        })
    }

    func testVerificationConfirmationErrorWithoutErrorResponseUnsuccessfulVerification() throws {
        let projectId = UUID().uuidString
        let accessId = UUID().uuidString

        let cause = apiClientError(
            with: UNSUCCESSFUL_VERIFICATION,
            context: [
                "randomKey": projectId,
                "accessId": accessId
            ]
        )
        mockAPI.verificationConfirmationError = cause
        mockAPI.verificationConfirmationResponse = nil
        mockAPI.verificationConfirmationResultCall = .failed

        try verificationConfirmationHandler(verificationConfirmationCompletionHandler: { activationTokenResponse, error in
            XCTAssertNil(activationTokenResponse)

            if let activationTokenError = error as? ActivationTokenError {
                if case let ActivationTokenError.unsuccessfulVerification(activationTokenErrorResponse: activationTokenErrorResponse) = activationTokenError {
                    XCTAssertNil(activationTokenErrorResponse)
                } else {
                    XCTFail("Error is no invalidVerificationCode")
                }
            } else {
                XCTFail("Error is no ActivationTokenError")
            }

        })
    }

    // MARK: Private

    private func verificationConfirmationHandler(
        verificationConfirmationCompletionHandler: @escaping ActivationTokenCompletionHandler
    ) throws {
        let expectation = XCTestExpectation(description: "Wait for verification confirmation")

        let handler = try VerificationConfirmationHandler(verificationURL: verificationURL, miraclAPI: mockAPI) { activationTokenResponse, error in
            verificationConfirmationCompletionHandler(activationTokenResponse, error)
            expectation.fulfill()
        }

        handler.handle()

        let waitResult = XCTWaiter.wait(for: [expectation], timeout: 10.0)
        if waitResult != .completed {
            XCTFail("Failed expectation")
        }
    }

    private func apiClientError(with code: String, context: [String: String]? = nil) -> APIError {
        let clientErrorData = ClientErrorData(
            code: code,
            info: "",
            context: context
        )

        return APIError.apiClientError(
            clientErrorData: clientErrorData,
            requestId: "",
            message: nil,
            requestURL: nil
        )
    }
}
