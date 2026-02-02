import MIRACLTrust
import XCTest

class GetCrossDeviceSessionTestCase: XCTest {
    func getCrossDeviceSession(qrCode: String) -> (CrossDeviceSession?, Error?) {
        let crossDeviceSessionExpectation = XCTestExpectation(
            description: "Get Cross Device Session from qrCode"
        )

        nonisolated(unsafe) var crossDeviceSession: CrossDeviceSession?
        nonisolated(unsafe) var returnedError: Error?
        MIRACLTrust.getInstance()._getCrossDeviceSessionFromQRCode(qrCode: qrCode) { session, error in
            crossDeviceSession = session
            returnedError = error
            crossDeviceSessionExpectation.fulfill()
        }

        _ = XCTWaiter.wait(for: [crossDeviceSessionExpectation], timeout: operationTimeout)
        return (crossDeviceSession, returnedError)
    }

    func getCrossDeviceSession(universalLinkURL: URL) -> (CrossDeviceSession?, Error?) {
        let crossDeviceSessionExpectation = XCTestExpectation(
            description: "Get Cross Device Session from qrCode"
        )

        nonisolated(unsafe) var crossDeviceSession: CrossDeviceSession?
        nonisolated(unsafe) var returnedError: Error?
        MIRACLTrust.getInstance()._getCrossDeviceSessionFromUniversalLinkURL(universalLinkURL: universalLinkURL) { session, error in
            crossDeviceSession = session
            returnedError = error
            crossDeviceSessionExpectation.fulfill()
        }

        _ = XCTWaiter.wait(for: [crossDeviceSessionExpectation], timeout: operationTimeout)
        return (crossDeviceSession, returnedError)
    }

    func getCrossDeviceSession(pushNotificationPayload: [AnyHashable: Any]) -> (CrossDeviceSession?, Error?) {
        let crossDeviceSessionExpectation = XCTestExpectation(
            description: "Get Cross Device Session from qrCode"
        )

        nonisolated(unsafe) var crossDeviceSession: CrossDeviceSession?
        nonisolated(unsafe) var returnedError: Error?
        MIRACLTrust.getInstance()._getCrossDeviceSessionFromPushNotificationPayload(pushNotificationPayload: pushNotificationPayload) { session, error in
            crossDeviceSession = session
            returnedError = error
            crossDeviceSessionExpectation.fulfill()
        }

        _ = XCTWaiter.wait(for: [crossDeviceSessionExpectation], timeout: operationTimeout)
        return (crossDeviceSession, returnedError)
    }
}
