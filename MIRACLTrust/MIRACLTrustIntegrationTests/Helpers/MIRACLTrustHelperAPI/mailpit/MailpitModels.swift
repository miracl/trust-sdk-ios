import Foundation

struct MailpitMessageResponse: Codable {
    let messages: [MailpitMessage]
}

struct MailpitMessage: Codable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id = "ID"
    }
}

struct MailpitMessageContent: Codable {
    let text: String

    enum CodingKeys: String, CodingKey {
        case text = "Text"
    }
}
