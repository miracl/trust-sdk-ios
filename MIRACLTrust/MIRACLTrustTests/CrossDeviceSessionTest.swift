import MIRACLTrust
import XCTest

final class CrossDeviceSessionTest: XCTestCase {
    func testCrossDeviceSessionForAuthenticationType() {
        let crossDeviceSession = CrossDeviceSession(
            userId: UUID().uuidString,
            projectId: UUID().uuidString,
            sessionId: UUID().uuidString,
            sessionDescription: UUID().uuidString,
            signingHash: ""
        )

        XCTAssertEqual(crossDeviceSession.type, .authentication)
    }

    func testCrossDeviceSessionForSigningType() {
        let crossDeviceSession = CrossDeviceSession(
            userId: UUID().uuidString,
            projectId: UUID().uuidString,
            sessionId: UUID().uuidString,
            sessionDescription: UUID().uuidString,
            signingHash: UUID().uuidString
        )

        XCTAssertEqual(crossDeviceSession.type, .signing)
    }
}
