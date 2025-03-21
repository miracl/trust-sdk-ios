@testable import MIRACLTrust
import XCTest

class SessionDetailsTestCase: XCTestCase {
    func getSessionDetails(qrCode: String) -> (AuthenticationSessionDetails?, Error?) {
        let waitForSessionDetails = XCTestExpectation(description: "wait for Session Details Code")

        nonisolated(unsafe) var returnedDetails: AuthenticationSessionDetails?
        nonisolated(unsafe) var returnedError: Error?

        MIRACLTrust
            .getInstance()
            .getAuthenticationSessionDetailsFromQRCode(
                qrCode: qrCode
            ) { details, error in
                returnedDetails = details
                returnedError = error
                waitForSessionDetails.fulfill()
            }

        let result = XCTWaiter.wait(for: [waitForSessionDetails], timeout: operationTimeout)
        if result != .completed {
            XCTFail("Something wrong happened")
        }

        return (returnedDetails, returnedError)
    }

    func getSessionDetails(universalLinkURL: URL) -> (SessionDetails?, Error?) {
        let waitForSessionDetails = XCTestExpectation(description: "wait for Session Details Code")

        nonisolated(unsafe) var returnedDetails: SessionDetails?
        nonisolated(unsafe) var returnedError: Error?

        MIRACLTrust
            .getInstance()
            .getAuthenticationSessionDetailsFromUniversalLinkURL(
                universalLinkURL: universalLinkURL
            ) { details, error in
                returnedDetails = details
                returnedError = error
                waitForSessionDetails.fulfill()
            }

        let result = XCTWaiter.wait(for: [waitForSessionDetails], timeout: operationTimeout)
        if result != .completed {
            XCTFail("Something wrong happened")
        }

        return (returnedDetails, returnedError)
    }

    func getSessionDetails(payload: [AnyHashable: Any]) -> (SessionDetails?, Error?) {
        let waitForSessionDetails = XCTestExpectation(description: "wait for Session Details Code")

        nonisolated(unsafe) var returnedDetails: SessionDetails?
        nonisolated(unsafe) var returnedError: Error?

        MIRACLTrust
            .getInstance()
            .getAuthenticationSessionDetailsFromPushNotificationPayload(
                pushNotificationPayload: payload
            ) { details, error in
                returnedDetails = details
                returnedError = error
                waitForSessionDetails.fulfill()
            }

        let result = XCTWaiter.wait(for: [waitForSessionDetails], timeout: operationTimeout)
        if result != .completed {
            XCTFail("Something wrong happened")
        }

        return (returnedDetails, returnedError)
    }
}
