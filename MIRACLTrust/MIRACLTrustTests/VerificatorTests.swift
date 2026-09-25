@testable import MIRACLTrust
import XCTest

class VerificatorTests: XCTestCase {
    var userId = UUID().uuidString
    var deviceName = UUID().uuidString
    var projectId = UUID().uuidString

    let mockUserStorage = MockUserStorage()
    let logger = DefaultLogger(level: .none)

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
            sessionIdentifier: nil,
            miraclAPI: api,
            deviceTagManager: DeviceTagManager(logger: logger),
            logger: logger
        ) { result in
            do {
                let verificationResponse = try result.get()
                XCTAssertEqual(verificationResponse.backoff, backoff)
                XCTAssertEqual(verificationResponse.method, EmailVerificationMethod.link)
            } catch {
                XCTFail("No verification response")
            }
            expectation.fulfill()
        }
        verificator.verify()

        wait(for: [expectation], timeout: 20.0)
    }

    func testInvalidAccessIdVerification() throws {
        let invalidAccessId = ""

        var api = MockAPI()
        api.verificationResponse = VerificationRequestResponse(backoff: 0, method: "link")
        api.verificationError = nil

        XCTAssertThrowsError(
            try Verificator(
                userId: userId,
                projectId: projectId,
                deviceName: deviceName,
                sessionIdentifier: invalidAccessId,
                miraclAPI: api,
                deviceTagManager: DeviceTagManager(logger: logger),
                logger: logger,
                completionHandler: { _ in }
            )
        ) { error in
            XCTAssertTrue(error is VerificationError)
            XCTAssertEqual(error as? VerificationError, VerificationError.invalidSessionDetails)
        }
    }

    func testEmptyUserIdVerification() throws {
        userId = ""

        var api = MockAPI()
        api.verificationResponse = VerificationRequestResponse(backoff: 0, method: "link")
        api.verificationError = nil

        XCTAssertThrowsError(
            try Verificator(
                userId: userId,
                projectId: projectId,
                deviceName: deviceName,
                sessionIdentifier: nil,
                miraclAPI: api,
                deviceTagManager: DeviceTagManager(logger: logger),
                logger: logger,
                completionHandler: { _ in }
            )
        ) { error in
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
            sessionIdentifier: nil,
            miraclAPI: api,
            deviceTagManager: DeviceTagManager(logger: logger),
            logger: logger,
            completionHandler: { result in
                guard case let .failure(error) = result else {
                    XCTFail("Expected .failure, but got \(result)")
                    return
                }
                assertError(current: error, expected: VerificationError.verificaitonFail(nil))
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
            sessionIdentifier: nil,
            miraclAPI: api,
            deviceTagManager: DeviceTagManager(logger: logger),
            logger: logger,
            completionHandler: { result in
                guard case let .failure(error) = result else {
                    XCTFail("Expected .failure, but got \(result)")
                    return
                }

                assertError(current: error, expected: desiredError)

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
            sessionIdentifier: nil,
            miraclAPI: api,
            deviceTagManager: DeviceTagManager(logger: logger),
            logger: logger,
            completionHandler: { result in
                guard case let .failure(error) = result else {
                    XCTFail("Expected .failure, but got \(result)")
                    return
                }

                assertError(current: error, expected: VerificationError.requestBackoff(backoff: backoff))

                if case let VerificationError.requestBackoff(backoffInError) = error {
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
            statusCode: 400,
            clientErrorData: clientErrorData,
            requestId: "",
            message: nil,
            requestURL: nil
        )
    }
}
