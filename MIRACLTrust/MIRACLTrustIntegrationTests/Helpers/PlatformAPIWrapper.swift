import XCTest

import MIRACLTrust

@objc class PlatformAPIWrapper: NSObject {
    let platformAPI = PlatformAPI()

    @objc func getVerificaitonURL(
        serviceAccountToken: String,
        projectId: String,
        projectURL: String,
        userId: String,
        accessId: String? = nil,
        expiration: Date? = nil
    ) -> URL? {
        let verificationUrlExpectation = XCTestExpectation(description: "wait for verification URL")
        nonisolated(unsafe) var verificationUrl: URL?

        platformAPI.getVerificationURL(
            serviceAccountToken: serviceAccountToken,
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

    @objc func startSession(
        projectId: String,
        projectURL: String,
        userId: String? = nil,
        hash: String? = nil,
        description: String? = nil
    ) -> StartSessionResult? {
        nonisolated(unsafe) var session: StartSessionResult?
        let accessIdExpectation = XCTestExpectation(description: "wait for Access Id")

        platformAPI
            .getAccessId(
                projectURL: projectURL,
                projectId: projectId,
                userId: userId,
                hash: hash,
                description: description,
                completionHandler: { session1, error in
                    if let session1 {
                        session = session1
                    } else if let error = error {
                        print("Error when creating access id: \(error)")
                    }
                    accessIdExpectation.fulfill()
                }
            )

        _ = XCTWaiter.wait(for: [accessIdExpectation], timeout: operationTimeout)
        return session
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

    func verifySignature(
        signingResult: SigningResult,
        serviceAccountToken: String,
        projectId: String,
        projectURL: String
    ) -> VerifySigningResponse? {
        nonisolated(unsafe) var verifySigningResponse: VerifySigningResponse?
        let expectation = XCTestExpectation(description: "Waiting for signature verification")

        platformAPI.verifySignature(
            for: signingResult.signature,
            timestamp: signingResult.timestamp,
            serviceAccountToken: serviceAccountToken,
            projectId: projectId,
            projectURL: projectURL
        ) { signingResponse, _ in
            verifySigningResponse = signingResponse
            expectation.fulfill()
        }
        _ = XCTWaiter.wait(for: [expectation], timeout: operationTimeout)

        return verifySigningResponse
    }

    func verifySignature(
        signature: Signature,
        timestamp: Date,
        serviceAccountToken: String,
        projectId: String,
        projectURL: String
    ) -> VerifySigningResponse? {
        nonisolated(unsafe) var verifySigningResponse: VerifySigningResponse?
        let expectation = XCTestExpectation(description: "Waiting for signature verification")

        platformAPI.verifySignature(
            for: signature,
            timestamp: timestamp,
            serviceAccountToken: serviceAccountToken,
            projectId: projectId,
            projectURL: projectURL
        ) { signingResponse, _ in
            verifySigningResponse = signingResponse
            expectation.fulfill()
        }
        _ = XCTWaiter.wait(for: [expectation], timeout: operationTimeout)

        return verifySigningResponse
    }

    func getVerificationURL(
        serviceAccountToken: String,
        projectId: String,
        projectURL: String,
        userId: String,
        accessId: String? = nil,
        expiration: Date? = nil
    ) async throws -> URL {
        let url: URL = try await withCheckedThrowingContinuation { continuation in
            platformAPI.getVerificationURL(
                serviceAccountToken: serviceAccountToken,
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
    ) async throws -> StartSessionResult {
        let session: StartSessionResult = try await withCheckedThrowingContinuation { continuation in
            platformAPI.getAccessId(
                projectURL: projectURL,
                projectId: projectId,
                userId: userId,
                hash: hash,
                description: description
            ) { session, error in
                if let session {
                    continuation.resume(returning: session)
                } else if let error {
                    continuation.resume(throwing: error)
                }
            }
        }

        return session
    }

    func getSessionStatus(
        projectURL: String,
        webOTT: String
    ) async throws -> SessionStatusResponse {
        let sessionStatusResponse: SessionStatusResponse =
            try await withCheckedThrowingContinuation { continuation in
                platformAPI.accessRequest(
                    projectURL: projectURL,
                    webOTT: webOTT
                ) { response, error in
                    if let response {
                        continuation.resume(returning: response)
                    } else if let error {
                        continuation.resume(throwing: error)
                    }
                }
            }

        return sessionStatusResponse
    }
}
