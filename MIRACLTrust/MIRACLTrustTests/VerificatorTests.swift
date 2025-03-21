@testable import MIRACLTrust
import XCTest

class VerificatorTests: XCTestCase {
    var userId = UUID().uuidString
    var deviceName = UUID().uuidString
    var projectId = UUID().uuidString

    func testSuccessfulVerification() throws {
        let backoff: Int64 = 1_688_029_968
        var api = MockAPI()
        api.verificationResponse = VerificationRequestResponse(backoff: backoff, method: "link")
        api.verificationError = nil

        let expectation = XCTestExpectation()
        let verificator = try Verificator(
            userId: userId,
            projectId: projectId,
            deviceName: deviceName,
            miraclAPI: api,
            completionHandler: { verified, error in
                XCTAssertNotNil(verified)
                XCTAssertNil(error)

                do {
                    let response = try XCTUnwrap(verified)
                    XCTAssertEqual(response.backoff, backoff)
                    XCTAssertEqual(response.method, EmailVerificationMethod.link)
                } catch {
                    XCTFail("Cannot unwrap Verification Response")
                }
                expectation.fulfill()
            }
        )
        verificator.verify()

        wait(for: [expectation], timeout: 20.0)
    }

    func testInvalidAccessIdVerification() throws {
        let invalidAccessId = ""

        var api = MockAPI()
        api.verificationResponse = VerificationRequestResponse(backoff: 0, method: "link")
        api.verificationError = nil

        XCTAssertThrowsError(try Verificator(
            userId: userId,
            projectId: projectId,
            deviceName: deviceName,
            accessId: invalidAccessId,
            miraclAPI: api,
            completionHandler: { _, _ in
            }
        )) { error in
            XCTAssertTrue(error is VerificationError)
            XCTAssertEqual(error as? VerificationError, VerificationError.invalidSessionDetails)
        }
    }

    func testEmptyUserIdVerification() throws {
        userId = ""

        var api = MockAPI()
        api.verificationResponse = VerificationRequestResponse(backoff: 0, method: "link")
        api.verificationError = nil

        XCTAssertThrowsError(try Verificator(
            userId: userId,
            projectId: projectId,
            deviceName: deviceName,
            miraclAPI: api,
            completionHandler: { _, _ in
            }
        )) { error in
            XCTAssertTrue(error is VerificationError)
            XCTAssertEqual(error as? VerificationError, VerificationError.emptyUserId)
        }
    }

    func testNilResponseVerification() throws {
        let expectation = XCTestExpectation()
        let userId = NSUUID().uuidString
        let deviceName = NSUUID().uuidString
        let projectId = UUID().uuidString

        var api = MockAPI()
        api.verificationResponse = nil
        api.verificationError = nil

        let verificator = try Verificator(
            userId: userId,
            projectId: projectId,
            deviceName: deviceName,
            miraclAPI: api,
            completionHandler: { response, error in
                XCTAssertNil(response)

                XCTAssertTrue(error is VerificationError)
                XCTAssertEqual(error as? VerificationError, VerificationError.verificaitonFail(nil))
                expectation.fulfill()
            }
        )

        verificator.verify()
        wait(for: [expectation], timeout: 20.0)
    }

    func testVerificationError() throws {
        let expectation = XCTestExpectation()

        let userId = NSUUID().uuidString
        let deviceName = NSUUID().uuidString
        let projectId = UUID().uuidString

        let cause = APIError.apiServerError(statusCode: 500, message: nil, requestURL: nil)
        let desiredError = VerificationError.verificaitonFail(cause)

        var api = MockAPI()
        api.verificationResponse = nil
        api.verificationError = cause

        let verificator = try Verificator(
            userId: userId,
            projectId: projectId,
            deviceName: deviceName,
            miraclAPI: api,
            completionHandler: { response, error in
                XCTAssertNil(response)

                XCTAssertTrue(error is VerificationError)
                XCTAssertEqual(error as? VerificationError, desiredError)
                expectation.fulfill()
            }
        )

        verificator.verify()
        wait(for: [expectation], timeout: 20.0)
    }

    func testBackoffError() throws {
        let expectation = XCTestExpectation()

        let backoff: Int64 = 1_688_029_968

        var api = MockAPI()
        api.verificationResponse = nil
        api.verificationError = apiClientError(
            with: BACKOFF_ERROR,
            context: ["backoff": String(backoff)]
        )

        let verificator = try Verificator(
            userId: userId,
            projectId: projectId,
            deviceName: deviceName,
            miraclAPI: api,
            completionHandler: { verified, error in
                XCTAssertNil(verified)
                XCTAssertNotNil(error)
                XCTAssertTrue(error is VerificationError)
                XCTAssertEqual(error as? VerificationError, VerificationError.requestBackoff(backoff: backoff))

                if let error, case let VerificationError.requestBackoff(backoffInError) = error {
                    XCTAssertEqual(backoffInError, backoff)
                }

                expectation.fulfill()
            }
        )
        verificator.verify()

        wait(for: [expectation], timeout: 20.0)
    }

    func testRequestBackoffError() throws {
        let expectation = XCTestExpectation()

        let backoff: Int64 = 1_688_029_968

        var api = MockAPI()
        api.verificationResponse = nil
        api.verificationError = apiClientError(with: BACKOFF_ERROR, context: ["backoff": String(backoff)])

        let verificator = try Verificator(
            userId: userId,
            projectId: projectId,
            deviceName: deviceName,
            miraclAPI: api,
            completionHandler: { verified, error in
                XCTAssertNil(verified)
                XCTAssertNotNil(error)
                XCTAssertTrue(error is VerificationError)
                XCTAssertEqual(error as? VerificationError, VerificationError.requestBackoff(backoff: backoff))

                if let error, case let VerificationError.requestBackoff(backoffInError) = error {
                    XCTAssertEqual(backoffInError, backoff)
                }

                expectation.fulfill()
            }
        )
        verificator.verify()

        wait(for: [expectation], timeout: 20.0)
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
