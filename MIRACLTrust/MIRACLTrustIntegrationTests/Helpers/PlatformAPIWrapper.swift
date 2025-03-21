import XCTest

import MIRACLTrust

@objc class PlatformAPIWrapper: NSObject {
    let processInfoDict = ProcessInfo.processInfo.environment
    let platformAPI = PlatformAPI(url: URL(string: ProcessInfo.processInfo.environment["platformURL"]!)!)

    @objc public func getVerificaitonURL(
        clientId: String,
        clientSecret: String,
        projectId: String,
        userId: String,
        accessId: String? = nil,
        expiration: Date? = nil
    ) -> URL? {
        let verificationUrlExpectation = XCTestExpectation(description: "wait for verification URL")
        nonisolated(unsafe) var verificationUrl: URL?

        platformAPI.getVerificationURL(
            clientId: clientId,
            clientSecret: clientSecret,
            projectId: projectId,
            userId: userId,
            accessId: accessId,
            expiration: expiration
        ) { url, error in

            if let url = url {
                verificationUrl = url
            } else if let error = error {
                print("Error when creating verification URL \(error)")
            }
            verificationUrlExpectation.fulfill()
        }
        _ = XCTWaiter.wait(for: [verificationUrlExpectation], timeout: operationTimeout)
        return verificationUrl
    }

    @objc public func getJWKS() -> String? {
        let jwksExpectation = XCTestExpectation(description: "wait for JWKS")
        nonisolated(unsafe) var jwkSet: String?

        platformAPI.getJWKS { jwks, error in

            if let jwks = jwks {
                jwkSet = jwks
            } else if let error = error {
                print("Error when fetching JWKS \(error)")
            }
            jwksExpectation.fulfill()
        }
        _ = XCTWaiter.wait(for: [jwksExpectation], timeout: operationTimeout)
        return jwkSet
    }

    @objc public func getAccessId(
        projectId: String,
        userId: String? = nil
    ) -> String? {
        nonisolated(unsafe) var accessId: String?
        let accessIdExpectation = XCTestExpectation(description: "wait for Access Id")

        platformAPI
            .getAccessId(projectId: projectId, userId: userId, completionHandler: { code, error in
                if let code = code {
                    accessId = code
                } else if let error = error {
                    print("Error when creating access id: \(error)")
                }
                accessIdExpectation.fulfill()
            })

        _ = XCTWaiter.wait(for: [accessIdExpectation], timeout: operationTimeout)
        return accessId
    }

    @objc public func startSigningSession(
        projectID: String,
        userID: String,
        hash: String,
        description: String
    ) -> String? {
        let sessionExpectation = XCTestExpectation(description: "Wait for getting Signing Session")
        nonisolated(unsafe) var qrCode: String?

        platformAPI.startSigningSession(
            projectID: projectID,
            userID: userID,
            hash: hash,
            description: description
        ) { signingSession, _ in
            qrCode = signingSession?.qrURL
            sessionExpectation.fulfill()
        }

        _ = XCTWaiter.wait(for: [sessionExpectation], timeout: operationTimeout)

        return qrCode
    }

    @objc func verifySignature(
        signingResult: SigningResult,
        clientId: String,
        clientSecret: String,
        projectId: String
    ) -> Bool {
        nonisolated(unsafe) var verifiedSignature = false
        let expectation = XCTestExpectation(description: "Waiting for signature verification")

        platformAPI.verifySignature(for: signingResult.signature, timestamp: signingResult.timestamp, clientId: clientId, clientSecret: clientSecret, projectId: projectId) { isVerified, _ in
            verifiedSignature = isVerified
            expectation.fulfill()
        }
        _ = XCTWaiter.wait(for: [expectation], timeout: operationTimeout)

        return verifiedSignature
    }
}
