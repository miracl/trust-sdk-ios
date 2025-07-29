import MIRACLTrust
import XCTest

class GetCrossDeviceSessionTestCase: XCTest {
    func getCrossDeviceSession(qrCode: String) -> (CrossDeviceSession?, Error?) {
        let getSigningSessionDetailsExpectation = XCTestExpectation(
            description: "Get Signing Session Details from qrCode"
        )

        nonisolated(unsafe) var crossDeviceSession: CrossDeviceSession?
        nonisolated(unsafe) var returnedError: Error?
        MIRACLTrust.getInstance()._getCrossDeviceSessionFromQRCode(qrCode: qrCode) { session, error in
            crossDeviceSession = session
            returnedError = error
            getSigningSessionDetailsExpectation.fulfill()
        }

        _ = XCTWaiter.wait(for: [getSigningSessionDetailsExpectation], timeout: operationTimeout)
        return (crossDeviceSession, returnedError)
    }

    func getCrossDeviceSession(universalLinkURL: URL) -> (CrossDeviceSession?, Error?) {
        let getSigningSessionDetailsExpectation = XCTestExpectation(
            description: "Get Signing Session Details from qrCode"
        )

        nonisolated(unsafe) var crossDeviceSession: CrossDeviceSession?
        nonisolated(unsafe) var returnedError: Error?
        MIRACLTrust.getInstance()._getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL: universalLinkURL) { session, error in
            crossDeviceSession = session
            returnedError = error
            getSigningSessionDetailsExpectation.fulfill()
        }

        _ = XCTWaiter.wait(for: [getSigningSessionDetailsExpectation], timeout: operationTimeout)
        return (crossDeviceSession, returnedError)
    }

    func getCrossDeviceSession(pushNotificationPayload: [AnyHashable: Any]) -> (CrossDeviceSession?, Error?) {
        let getSigningSessionDetailsExpectation = XCTestExpectation(
            description: "Get Signing Session Details from qrCode"
        )

        nonisolated(unsafe) var crossDeviceSession: CrossDeviceSession?
        nonisolated(unsafe) var returnedError: Error?
        MIRACLTrust.getInstance()._getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload: pushNotificationPayload) { session, error in
            crossDeviceSession = session
            returnedError = error
            getSigningSessionDetailsExpectation.fulfill()
        }

        _ = XCTWaiter.wait(for: [getSigningSessionDetailsExpectation], timeout: operationTimeout)
        return (crossDeviceSession, returnedError)
    }
}
