import XCTest

import MIRACLTrust

@objc class PlatformAPIWrapper: NSObject {
    let platformAPI = PlatformAPI()

    @objc func getVerificaitonURL(
        clientId: String,
        clientSecret: String,
        projectId: String,
        projectURL: String,
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
            projectURL: projectURL,
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

    @objc func getJWKS(projectURL: String) -> String? {
        let jwksExpectation = XCTestExpectation(description: "wait for JWKS")
        nonisolated(unsafe) var jwkSet: String?

        platformAPI.getJWKS(projectURL: projectURL) { jwks, error in
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

    @objc func getAccessId(
        projectId: String,
        projectURL: String,
        userId: String? = nil,
        hash: String? = nil,
        description: String? = nil
    ) -> String? {
        nonisolated(unsafe) var accessId: String?
        let accessIdExpectation = XCTestExpectation(description: "wait for Access Id")

        platformAPI
            .getAccessId(
                projectURL: projectURL,
                projectId: projectId,
                userId: userId,
                hash: hash,
                description: description,
                completionHandler: { code, error in
                    if let code = code {
                        accessId = code
                    } else if let error = error {
                        print("Error when creating access id: \(error)")
                    }
                    accessIdExpectation.fulfill()
                }
            )

        _ = XCTWaiter.wait(for: [accessIdExpectation], timeout: operationTimeout)
        return accessId
    }

    @objc func startSigningSession(
        projectID: String,
        projectURL: String,
        userID: String,
        hash: String,
        description: String
    ) -> String? {
        let sessionExpectation = XCTestExpectation(description: "Wait for getting Signing Session")
        nonisolated(unsafe) var qrCode: String?

        platformAPI.startSigningSession(
            projectID: projectID,
            projectURL: projectURL,
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
        projectId: String,
        projectURL: String
    ) -> Bool {
        nonisolated(unsafe) var verifiedSignature = false
        let expectation = XCTestExpectation(description: "Waiting for signature verification")

        platformAPI.verifySignature(for: signingResult.signature, timestamp: signingResult.timestamp, clientId: clientId, clientSecret: clientSecret, projectId: projectId, projectURL: projectURL) { isVerified, _ in
            verifiedSignature = isVerified
            expectation.fulfill()
        }
        _ = XCTWaiter.wait(for: [expectation], timeout: operationTimeout)

        return verifiedSignature
    }

    func getVerificationURL(
        clientId: String,
        clientSecret: String,
        projectId: String,
        projectURL: String,
        userId: String,
        accessId: String? = nil,
        expiration: Date? = nil
    ) async throws -> URL {
        let url: URL = try await withCheckedThrowingContinuation { continuation in
            platformAPI.getVerificationURL(
                clientId: clientId,
                clientSecret: clientSecret,
                projectId: projectId,
                projectURL: projectURL,
                userId: userId,
                accessId: accessId,
                expiration: expiration
            ) { url, error in
                if let url {
                    continuation.resume(returning: url)
                } else if let error {
                    continuation.resume(throwing: error)
                }
            }
        }
        return url
    }

    func getAsyncAccessId(
        projectId: String,
        projectURL: String,
        userId: String? = nil,
        hash: String? = nil,
        description: String? = nil
    ) async throws -> String {
        let accessId: String = try await withCheckedThrowingContinuation { continuation in
            platformAPI.getAccessId(
                projectURL: projectURL,
                projectId: projectId,
                userId: userId,
                hash: hash,
                description: description
            ) { accessId, error in
                if let accessId {
                    continuation.resume(returning: accessId)
                } else if let error {
                    continuation.resume(throwing: error)
                }
            }
        }

        return accessId
    }
}
