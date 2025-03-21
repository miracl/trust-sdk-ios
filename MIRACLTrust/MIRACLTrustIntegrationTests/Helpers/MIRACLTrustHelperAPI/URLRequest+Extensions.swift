import MIRACLTrust

extension URLRequest {
    static func sessionRequest(url: URL, projectId: String, userId: String?) -> Self? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.path = "/rps/v2/session"
        guard let url = components.url else {
            fatalError("Error with creating URL from components")
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        do {
            let body = SessionRequestBody(projectId: projectId, userId: userId)
            let bodyData = try JSONEncoder().encode(body)
            request.httpBody = bodyData
        } catch {
            return nil
        }

        return request
    }

    static func verifyJWTSignature(
        url: URL,
        token: String,
        projectId: String
    ) -> Self? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        components.path = "/authentication"
        components.queryItems = [
            URLQueryItem(name: "project_id", value: projectId)
        ]

        guard let url = components.url else {
            return nil
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        do {
            let body = VerifyJWTSignatureRequestBody(token: token)
            let bodyData = try JSONEncoder().encode(body)
            urlRequest.httpBody = bodyData
        } catch {
            return nil
        }

        return urlRequest
    }

    static func verifySignatureRequest(
        url: URL,
        signature: Signature,
        timestamp: Date,
        clientId: String,
        clientSecret: String,
        projectId: String
    ) -> Self? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        components.path = "/dvs/verify"
        components.queryItems = [
            URLQueryItem(name: "project_id", value: projectId)
        ]

        guard let url = components.url else {
            return nil
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        let authHeaderData = Data("\(clientId):\(clientSecret)".utf8)
        let base64Str = authHeaderData.base64EncodedString()
        urlRequest.addValue("Basic \(base64Str)", forHTTPHeaderField: "Authorization")

        do {
            let body = VerifySigningRequestBody(
                signature: signature,
                timestamp: Int32(timestamp.timeIntervalSince1970)
            )
            let bodyData = try JSONEncoder().encode(body)
            urlRequest.httpBody = bodyData
        } catch {
            return nil
        }

        return urlRequest
    }

    static func verifySignatureRequest(
        url: URL,
        signature: Signature,
        timestamp: Date,
        projectId: String
    ) -> Self? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        components.path = "/signature/verification"
        components.queryItems = [
            URLQueryItem(name: "project_id", value: projectId)
        ]

        guard let url = components.url else {
            return nil
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        do {
            let body = VerifySigningRequestBody(
                signature: signature,
                timestamp: Int32(timestamp.timeIntervalSince1970)
            )
            let bodyData = try JSONEncoder().encode(body)
            urlRequest.httpBody = bodyData
        } catch {
            return nil
        }

        return urlRequest
    }

    static func verificationURLRequest(
        url: URL,
        clientId: String,
        clientSecret: String,
        projectId: String,
        userId: String,
        expiration: Date? = nil,
        accessId: String? = nil
    ) -> Self? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.path = "/verification"

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        let body = VerificationRequestBody(
            projectId: projectId,
            userId: userId,
            accessId: accessId,
            expiration: expiration.flatMap { Int($0.timeIntervalSince1970) }
        )

        let encoder = JSONEncoder()
        if let postData = try? encoder.encode(body) {
            request.httpBody = postData
        }

        let authHeaderData = Data("\(clientId):\(clientSecret)".utf8)
        let base64Str = authHeaderData.base64EncodedString()
        request.addValue("Basic \(base64Str)", forHTTPHeaderField: "Authorization")

        return request
    }

    static func jwksRequest(url: URL) -> Self? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.path = "/.well-known/jwks"

        guard let url = components.url else {
            return nil
        }

        return URLRequest(url: url)
    }

    static func signingSessionRequest(
        url: URL,
        projectID: String,
        userID: String,
        hash: String,
        description: String
    ) -> URLRequest? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.path = "/dvs/session"

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        let requestBody = SigningSessionRequestBody(
            projectID: projectID,
            userID: userID,
            hash: hash,
            description: description
        )

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            return nil
        }

        return request
    }

    static func gmailAccessTokenRequest(for credentials: Credentials, refreshToken: String) -> URLRequest? {
        var request = URLRequest(url: URL(string: credentials.installed.tokenURI)!)
        request.httpMethod = "POST"

        let body = "client_id=\(credentials.installed.clientID)&client_secret=\(credentials.installed.clientSecret)&refresh_token=\(refreshToken)&grant_type=refresh_token&access_type=offline"
        request.httpBody = body.data(using: .utf8)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        return request
    }

    static func gmailSingleMessageRequest(messageId: String, accessToken: String) -> URLRequest? {
        let messageEndpoint = "https://gmail.googleapis.com/gmail/v1/users/me/messages/\(messageId)?format=full"
        var request = URLRequest(url: URL(string: messageEndpoint)!)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }

    static func gmailGetMessageContentRequest(query: String, accessToken: String) -> URLRequest? {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let listEndpoint = "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=\(encodedQuery)&maxResults=1"

        var request = URLRequest(url: URL(string: listEndpoint)!)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return request
    }
}
