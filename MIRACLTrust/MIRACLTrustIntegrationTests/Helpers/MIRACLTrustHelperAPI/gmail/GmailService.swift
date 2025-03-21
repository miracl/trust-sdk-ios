import Foundation

private struct MessagesList: Codable {
    let messages: [Message]?
}

private struct Message: Codable {
    let id: String
    let payload: Payload?
}

private struct Payload: Codable {
    let parts: [Part]?
}

private struct Body: Codable {
    let size: Int
    let data: String?
}

private struct Part: Codable {
    let body: Body?
}

public enum GmailServiceError: Error {
    case gmailServiceError(Error?)
    case gmailServiceErrorWithMessage(String)
}

struct GmailService {
    func getVerificationURL(
        receiver: String,
        timestamp: Date
    ) async throws -> URL? {
        let accessToken = try await getAccessToken()
        let message = try await getMessageContent(accessToken: accessToken, timestamp: timestamp, receiver: receiver)

        let regexPattern = "https?://.*/verification/confirmation\\?code=([^&]*)&user_id=(\\S*)"
        if let regex = try? NSRegularExpression(pattern: regexPattern, options: []),
           let match = regex.firstMatch(in: message, options: [], range: NSRange(message.startIndex..., in: message)) {
            let range = Range(match.range(at: 0), in: message)
            if let verificationURL = range != nil ? URL(string: String(message[range!])) : nil {
                return verificationURL
            }
        }

        return nil
    }

    public func getVerificationCode(
        receiver: String,
        timestamp: Date
    ) async throws -> String? {
        let accessToken = try await getAccessToken()
        let message = try await getMessageContent(accessToken: accessToken, timestamp: timestamp, receiver: receiver)

        let regexPattern = "Type the following code to register your device: (\\d{6})"
        if let regex = try? NSRegularExpression(pattern: regexPattern, options: []),
           let match = regex.firstMatch(in: message, options: [], range: NSRange(message.startIndex..., in: message)) {
            let range = Range(match.range(at: 1), in: message)
            if let verificationCode = range != nil ? String(message[range!]) : nil {
                return verificationCode
            }
        }

        return nil
    }

    // MARK: Private

    private func getMessageContent(accessToken: String, timestamp: Date, receiver: String) async throws -> String {
        let session = URLSession.shared
        let query = "from:noreply@trust.miracl.cloud to:\(receiver) after:\(Int(timestamp.timeIntervalSince1970))"
        guard let request = URLRequest.gmailGetMessageContentRequest(query: query, accessToken: accessToken) else {
            throw GmailServiceError.gmailServiceErrorWithMessage("Cannot create gmailGetMessageContentRequest")
        }

        let (data, _) = try await session.data(for: request)
        let messagesList = try JSONDecoder().decode(MessagesList.self, from: data)

        if let firstMessage = messagesList.messages?.first {
            guard let request = URLRequest.gmailSingleMessageRequest(messageId: firstMessage.id, accessToken: accessToken) else {
                throw GmailServiceError.gmailServiceErrorWithMessage("Cannot create gmailSingleMessageRequest")
            }

            let (data, _) = try await session.data(for: request)
            let message = try JSONDecoder().decode(Message.self, from: data)

            if let partData = message.payload?.parts?.first?.body?.data,
               let decodedData = Data(base64Encoded: partData, options: .ignoreUnknownCharacters),
               let partContent = String(data: decodedData, encoding: .utf8) {
                return partContent
            }
        }

        throw GmailServiceError.gmailServiceErrorWithMessage("Cannot find message for \(receiver)")
    }

    private func getAccessToken() async throws -> String {
        guard let (credentials, tokenInfo) = loadCredentials(),
              let refreshToken = tokenInfo.refreshToken else {
            throw GmailServiceError.gmailServiceErrorWithMessage("Cannot load credentials")
        }

        guard let request = URLRequest.gmailAccessTokenRequest(for: credentials, refreshToken: refreshToken) else {
            throw GmailServiceError.gmailServiceErrorWithMessage("Cannot create gmailAccessTokenRequest")
        }

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: "myCacheDirectory")

        let (data, _) = try await URLSession(configuration: config).data(for: request)
        let tokenResponse = try JSONDecoder().decode(Token.self, from: data)

        return tokenResponse.accessToken
    }

    private func loadCredentials() -> (Credentials, Token)? {
        do {
            let credentials = ProcessInfo.processInfo.environment["gmailCredentials"]!
            let token = ProcessInfo.processInfo.environment["gmailToken"]!
            let decoder = JSONDecoder()

            let googleCredentails = try decoder.decode(Credentials.self, from: credentials.data(using: .utf8)!)
            let googleToken = try decoder.decode(Token.self, from: token.data(using: .utf8)!)

            return (googleCredentails, googleToken)
        } catch {
            print("Failed to decode credentials: \(error.localizedDescription)")
            return nil
        }
    }
}
