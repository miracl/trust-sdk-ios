import Foundation

struct MailpitAPI {
    private let mailpitURL = URL(string: ProcessInfo.processInfo.environment["mailpitURL"]!)!

    private let mailpitUser = ProcessInfo.processInfo.environment["mailpitUser"]!
    private let mailpitPass = ProcessInfo.processInfo.environment["mailpitPass"]!

    func searchMessage(from: String, to: String, after: Date) async throws -> String {
        guard let request = URLRequest.mailpitSearchRequest(
            mailpitURL: mailpitURL,
            mailpitUser: mailpitUser,
            mailpitPass: mailpitPass,
            from: from,
            to: to,
            timestamp: after
        ) else {
            throw MailpitError.searchError(nil, "Cannot create URL Request")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 200 {
                throw MailpitError.searchError(nil, "API Error = \(statusCode)")
            }

            let messagesResponse = try JSONDecoder().decode(MailpitMessageResponse.self, from: data)

            if let id = messagesResponse.messages.first?.id {
                return id
            } else {
                throw MailpitError.searchError(nil, "No messages found")
            }
        } catch {
            throw MailpitError.searchError(error, nil)
        }
    }

    func getMessage(id: String) async throws -> String {
        guard let request = URLRequest.mailpitGetMessageRequest(
            mailpitURL: mailpitURL,
            mailpitUser: mailpitUser,
            mailpitPass: mailpitPass,
            id: id
        ) else {
            throw MailpitError.searchError(nil, "Cannot create URL Request")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode != 200 {
                throw MailpitError.getMessageError(nil, "API Error = \(statusCode)")
            }
            let messagesResponse = try JSONDecoder().decode(MailpitMessageContent.self, from: data)
            return messagesResponse.text
        } catch {
            throw MailpitError.getMessageError(error, nil)
        }
    }
}
