@testable import MIRACLTrust
import XCTest

class SigningTestCase {
    var signingPinCode = ""

    func signMessage(message: Data, user: User, signingSessionDetails: SigningSessionDetails? = nil) -> (SigningResult?, Error?) {
        let waitForSignature = XCTestExpectation(description: "wait for SigningUser")

        nonisolated(unsafe) var returnedSigningResult: SigningResult?
        nonisolated(unsafe) var returnedError: Error?

        let pinCode = signingPinCode

        if let signingSessionDetails {
            MIRACLTrust.getInstance()._sign(
                message: message,
                user: user,
                signingSessionDetails: signingSessionDetails,
                didRequestSigningPinHandler: { pinHandler in
                    pinHandler(pinCode)
                }, completionHandler: { signature, error in
                    returnedSigningResult = signature
                    returnedError = error
                    waitForSignature.fulfill()
                }
            )
        } else {
            MIRACLTrust.getInstance().sign(
                message: message,
                user: user,
                didRequestSigningPinHandler: { pinHandler in
                    pinHandler(pinCode)
                }, completionHandler: { signature, error in
                    returnedSigningResult = signature
                    returnedError = error
                    waitForSignature.fulfill()
                }
            )
        }

        let result = XCTWaiter.wait(for: [waitForSignature], timeout: operationTimeout)
        if result != .completed {
            XCTFail("Something wrong happened")
        }

        return (returnedSigningResult, returnedError)
    }

    func signMessage(crossDeviceSession: CrossDeviceSession, user: User) -> (Bool, Error?) {
        let waitForSignature = XCTestExpectation(description: "wait for SigningUser")

        nonisolated(unsafe) var returnedSigningResult = false
        nonisolated(unsafe) var returnedError: Error?

        let pinCode = signingPinCode
        MIRACLTrust.getInstance()._sign(crossDeviceSession: crossDeviceSession, user: user) { pinHandler in
            pinHandler(pinCode)
        } completionHandler: { isSigned, error in
            returnedSigningResult = isSigned
            returnedError = error
            waitForSignature.fulfill()
        }

        let result = XCTWaiter.wait(for: [waitForSignature], timeout: operationTimeout)
        if result != .completed {
            XCTFail("Something wrong happened")
        }

        return (returnedSigningResult, returnedError)
    }
}
