import MIRACLTrust

@objc public class ActivationResponse: NSObject, Codable {
    var actToken = ""
}

@objc public class PlatformAPI: NSObject {
    var requestExecutor = HTTPRequestExecutor()

    public var url: URL

    @objc public init(url: URL) {
        self.url = url
    }

    @objc public func getAccessId(
        projectId: String,
        userId: String? = nil,
        completionHandler: @escaping @Sendable (String?, Error?) -> Void
    ) {
        guard let request = URLRequest.sessionRequest(url: url, projectId: projectId, userId: userId) else {
            return
        }

        requestExecutor.executeHTTPRequest(request: request) { (result: Result<Session?, HelperAPIError>) in
            switch result {
            case let .success(session):
                if let session = session {
                    if let urlComponents = URLComponents(url: session.qrURL, resolvingAgainstBaseURL: false) {
                        if let fragment = urlComponents.fragment {
                            completionHandler(fragment, nil)
                        }
                    }
                }
            case let .failure(failure):
                completionHandler(nil, failure)
            }
        }
    }

    public func getVerificationURL(
        clientId: String,
        clientSecret: String,
        projectId: String,
        userId: String,
        accessId: String? = nil,
        expiration: Date? = nil,
        completionHandler: @escaping @Sendable (URL?, Error?) -> Void
    ) {
        guard let request = URLRequest.verificationURLRequest(
            url: url,
            clientId: clientId,
            clientSecret: clientSecret,
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

    public func getJWKS(completionHandler: @escaping @Sendable (String?, Error?) -> Void) {
        guard let request = URLRequest.jwksRequest(url: url) else {
            return
        }

        let task = URLSession.shared.dataTask(with: request) { responseData, response, error in
            if error != nil {
                DispatchQueue.main.async {
                    completionHandler(nil, HelperAPIError.internalError)
                }
                return
            }

            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    DispatchQueue.main.async {
                        completionHandler(nil, HelperAPIError.internalError)
                    }
                    return
                }
            }

            guard let data = responseData else {
                DispatchQueue.main.async {
                    completionHandler(nil, HelperAPIError.noData)
                }
                return
            }

            if data.isEmpty {
                DispatchQueue.main.async {
                    completionHandler(nil, nil)
                }
                return
            }

            completionHandler(String(data: data, encoding: String.Encoding.utf8), nil)
        }

        task.resume()
    }

    @objc public func startSigningSession(
        projectID: String,
        userID: String,
        hash: String,
        description: String,
        completionHandler: @escaping @Sendable (SigningSession?, Error?) -> Void
    ) {
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

    public func verifySignature(
        for signature: Signature,
        timestamp: Date,
        clientId: String,
        clientSecret: String,
        projectId: String,
        completionHandler: @escaping @Sendable (Bool, Error?) -> Void
    ) {
        guard let request = URLRequest.verifySignatureRequest(url: url, signature: signature, timestamp: timestamp, clientId: clientId, clientSecret: clientSecret, projectId: projectId) else {
            return
        }

        requestExecutor.executeHTTPRequest(request: request) { (result: Result<EmptyResponse?, HelperAPIError>) in
            switch result {
            case .success:
                completionHandler(true, nil)
            case let .failure(error):
                completionHandler(false, error)
            }
        }
    }
}
