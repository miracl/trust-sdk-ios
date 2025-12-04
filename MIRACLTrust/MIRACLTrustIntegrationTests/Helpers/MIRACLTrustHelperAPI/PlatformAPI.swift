import MIRACLTrust

@objc public class ActivationResponse: NSObject, Codable {
    var actToken = ""
}

@objc public class PlatformAPI: NSObject {
    var requestExecutor = HTTPRequestExecutor()

    @objc public func getAccessId(
        projectURL: String,
        projectId: String,
        userId: String? = nil,
        hash: String? = nil,
        description: String? = nil,
        completionHandler: @escaping @Sendable (StartSessionResult?, Error?) -> Void
    ) {
        guard let url = URL(string: projectURL) else {
            return
        }

        guard let request = URLRequest.sessionRequest(
            url: url,
            projectId: projectId,
            userId: userId,
            hash: hash,
            description: description
        ) else {
            return
        }

        requestExecutor.executeHTTPRequest(request: request) { (result: Result<StartSessionResponse?, HelperAPIError>) in
            switch result {
            case let .success(session):
                if let session = session {
                    if let urlComponents = URLComponents(url: session.qrURL, resolvingAgainstBaseURL: false) {
                        if let fragment = urlComponents.fragment {
                            let session = StartSessionResult(accessId: fragment, webOTT: session.webOTT)
                            completionHandler(session, nil)
                        }
                    }
                }
            case let .failure(failure):
                completionHandler(nil, failure)
            }
        }
    }

    public func getVerificationURL(
        serviceAccountToken: String,
        projectId: String,
        projectURL: String,
        userId: String,
        accessId: String? = nil,
        expiration: Date? = nil,
        completionHandler: @escaping @Sendable (URL?, Error?) -> Void
    ) {
        guard let url = URL(string: projectURL) else {
            return
        }

        guard let request = URLRequest.verificationURLRequest(
            url: url,
            serviceAccountToken: serviceAccountToken,
            projectId: projectId,
            userId: userId,
            expiration: expiration,
            accessId: accessId
        ) else {
            return
        }

        requestExecutor.executeHTTPRequest(request: request) { (result: Result<HelperAPIVerificationResponse?, HelperAPIError>) in
            switch result {
            case let .success(success):
                guard let verificationURL = success?.verificationURL else {
                    completionHandler(nil, nil)
                    return
                }
                completionHandler(verificationURL, nil)
            case let .failure(failure):
                completionHandler(nil, failure)
            }
        }
    }

    public func accessRequest(
        projectURL: String,
        webOTT: String,
        completionHandler: @escaping @Sendable (SessionStatusResponse?, Error?) -> Void
    ) {
        guard let url = URL(string: projectURL) else {
            return
        }

        guard let request = URLRequest.accessRequest(url: url, webOTT: webOTT) else {
            return
        }

        requestExecutor.executeHTTPRequest(request: request) { (result: Result<SessionStatusResponse?, HelperAPIError>) in
            switch result {
            case let .success(success):
                completionHandler(success, nil)
            case let .failure(failure):
                completionHandler(nil, failure)
            }
        }
    }

    @objc public func startSigningSession(
        projectID: String,
        projectURL: String,
        userID: String,
        hash: String,
        description: String,
        completionHandler: @escaping @Sendable (SigningSession?, Error?) -> Void
    ) {
        guard let url = URL(string: projectURL) else {
            return
        }

        guard let request = URLRequest.signingSessionRequest(
            url: url,
            projectID: projectID,
            userID: userID,
            hash: hash,
            description: description
        ) else {
            return
        }

        requestExecutor.executeHTTPRequest(request: request) { (result: Result<SigningSessionResponse?, HelperAPIError>) in
            switch result {
            case let .success(success):
                let result = SigningSession(qrURL: success?.qrURL ?? "")
                completionHandler(result, nil)
            case let .failure(failure):
                completionHandler(nil, failure)
            }
        }
    }

    func verifySignature(
        for signature: Signature,
        timestamp: Date,
        serviceAccountToken: String,
        projectId: String,
        projectURL: String,
        completionHandler: @escaping @Sendable (VerifySigningResponse?, Error?) -> Void
    ) {
        guard let url = URL(string: projectURL) else {
            return
        }

        guard let request = URLRequest.verifySignatureRequest(url: url, signature: signature, timestamp: timestamp, serviceAccountToken: serviceAccountToken, projectId: projectId) else {
            return
        }

        requestExecutor.executeHTTPRequest(request: request) { (result: Result<VerifySigningResponse?, HelperAPIError>) in
            switch result {
            case let .success(success):
                completionHandler(success, nil)
            case let .failure(error):
                completionHandler(nil, error)
            }
        }
    }
}
