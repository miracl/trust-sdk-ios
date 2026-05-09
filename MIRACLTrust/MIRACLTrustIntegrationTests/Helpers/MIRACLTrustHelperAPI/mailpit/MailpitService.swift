import Foundation

enum MailpitError: Error {
    case searchError(Error?, String?)
    case getMessageError(Error?, String?)
}

struct MailpitService {
    let mailpitAPI = MailpitAPI()

    func getVerificationURL(
        receiver: String,
        timestamp: Date
    ) async throws -> URL? {
        let messageId = try await mailpitAPI.searchMessage(from: "noreply@trust.miracl.cloud", to: receiver, after: timestamp)
        let messageContent = try await mailpitAPI.getMessage(id: messageId)

        let regex = try Regex("https?://.*/verification/confirmation\\?code=([^&]*)&user_id=(\\S*)")
        if let match = try regex.firstMatch(in: messageContent) {
            let result = String(match.0)
            return URL(string: result)
        }

        return nil
    }

    func getVerificationCode(
        receiver: String,
        timestamp: Date
    ) async throws -> String? {
        let messageId = try await mailpitAPI.searchMessage(from: "noreply@trust.miracl.cloud", to: receiver, after: timestamp)
        let messageContent = try await mailpitAPI.getMessage(id: messageId)

        let regex = try Regex("Type the following code to register your device: (\\d{6})")
        if let match = try regex.firstMatch(in: messageContent) {
            if let code = String(match.0).components(separatedBy: ": ").last {
                return code
            }
        }

        return nil
    }
}
