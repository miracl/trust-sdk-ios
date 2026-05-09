import MIRACLTrust

extension URLRequest {
    static func sessionRequest(url: URL, projectId: String, userId: String?, hash: String?, description: String?) -> Self? {
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
            let body = SessionRequestBody(projectId: projectId, userId: userId, hash: hash, description: description)
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
        serviceAccountToken: String,
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
        urlRequest.addValue("Bearer \(serviceAccountToken)", forHTTPHeaderField: "Authorization")

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
        serviceAccountToken: String,
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

        request.addValue("Bearer \(serviceAccountToken)", forHTTPHeaderField: "Authorization")

        return request
    }

    static func accessRequest(
        url: URL,
        webOTT: String
    ) -> URLRequest? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.path = "/rps/v2/access"

        guard let url = components.url else {
            return nil
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"

        let requestBody = SessionStatusRequestBody(webOTT: webOTT)

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            return nil
        }

        return request
    }

    static func mailpitSearchRequest(
        mailpitURL: URL,
        mailpitUser: String,
        mailpitPass: String,
        from: String,
        to: String,
        timestamp: Date
    ) -> URLRequest? {
        guard var urlComponents = URLComponents(url: mailpitURL, resolvingAgainstBaseURL: true) else {
            return nil
        }

        urlComponents.path = "/api/v1/search"
        urlComponents.queryItems = [
            URLQueryItem(
                name: "query",
                value: "from:\(from) to:\(to) after:\(Int(timestamp.timeIntervalSince1970))"
            )
        ]

        guard let urlWithQuery = urlComponents.url else {
            return nil
        }

        let mailpitCredentials = "\(mailpitUser):\(mailpitPass)"
        guard let loginData = mailpitCredentials.data(using: .utf8) else {
            return nil
        }
        let base64LoginString = loginData.base64EncodedString()

        var request = URLRequest(url: urlWithQuery)
        request.httpMethod = "GET"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        return request
    }

    static func mailpitGetMessageRequest(
        mailpitURL: URL,
        mailpitUser: String,
        mailpitPass: String,
        id: String
    ) -> URLRequest? {
        guard var urlComponents = URLComponents(url: mailpitURL, resolvingAgainstBaseURL: true) else {
            return nil
        }
        urlComponents.path = "/api/v1/message/\(id)"

        guard let urlWithQuery = urlComponents.url else {
            return nil
        }

        let mailpitCredentials = "\(mailpitUser):\(mailpitPass)"
        guard let loginData = mailpitCredentials.data(using: .utf8) else {
            return nil
        }
        let base64LoginString = loginData.base64EncodedString()

        var request = URLRequest(url: urlWithQuery)
        request.httpMethod = "GET"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        return request
    }
}
