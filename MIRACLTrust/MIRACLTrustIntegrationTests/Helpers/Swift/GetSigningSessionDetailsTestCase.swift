@testable import MIRACLTrust
import XCTest

class GetSigningSessionDetailsTestCase: XCTest {
    func getSigningSessionDetails(qrCode: String) -> (SigningSessionDetails?, Error?) {
        let getSigningSessionDetailsExpectation = XCTestExpectation(
            description: "Get Signing Session Details from qrCode"
        )

        nonisolated(unsafe) var signingSessionDetails: SigningSessionDetails?
        nonisolated(unsafe) var returnedError: Error?
        MIRACLTrust
            .getInstance()
            .getSigningSessionDetailsFromQRCode(
                qrCode: qrCode,
                completionHandler: { sessionDetails, error in
                    signingSessionDetails = sessionDetails
                    returnedError = error
                    getSigningSessionDetailsExpectation.fulfill()
                }
            )

        _ = XCTWaiter.wait(for: [getSigningSessionDetailsExpectation], timeout: operationTimeout)
        return (signingSessionDetails, returnedError)
    }
}
