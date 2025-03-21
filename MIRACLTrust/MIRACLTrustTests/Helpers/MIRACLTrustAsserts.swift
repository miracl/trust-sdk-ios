import MIRACLTrust
import XCTest

public func assertError<T: Error & Equatable>(current: Error?, expected: T) {
    XCTAssertNotNil(current)
    XCTAssertTrue(current is T)
    XCTAssertEqual(current as? T, expected)
}

public func assertSessionDetails(
    sessionDetails: AuthenticationSessionDetails?,
    randomString: String,
    accessId: String,
    randomPinLength: Int
) {
    do {
        let fetchedDetails = try XCTUnwrap(sessionDetails)

        XCTAssertEqual(fetchedDetails.userId, randomString)
        XCTAssertEqual(fetchedDetails.projectId, randomString)
        XCTAssertEqual(fetchedDetails.projectName, randomString)
        XCTAssertEqual(fetchedDetails.projectLogoURL, randomString)
        XCTAssertEqual(fetchedDetails.accessId, accessId)
        XCTAssertEqual(fetchedDetails.pinLength, randomPinLength)
        XCTAssertEqual(fetchedDetails.verificationMethod, .fullCustom)
        XCTAssertEqual(fetchedDetails.verificationURL, randomString)
        XCTAssertEqual(fetchedDetails.identityTypeLabel, randomString)
        XCTAssertEqual(fetchedDetails.verificationCustomText, randomString)
        XCTAssertEqual(fetchedDetails.identityType, IdentityType.email)
        XCTAssertEqual(fetchedDetails.quickCodeEnabled, true)
        XCTAssertEqual(fetchedDetails.limitQuickCodeRegistration, true)

    } catch {
        XCTFail("Get session detail failed")
    }
}
