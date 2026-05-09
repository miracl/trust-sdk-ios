import Foundation

struct MailpitServiceWrapper {
    private let mailpitRetryCount = 60
    private let mailpitRetryTimeout: UInt32 = 10

    private let mailpitService = MailpitService()

    func getVerificationURL(
        receiver: String,
        timestamp: Date
    ) async throws -> URL? {
        for _ in 1 ... mailpitRetryCount {
            do {
                if let verificationURL = try await mailpitService.getVerificationURL(receiver: receiver, timestamp: timestamp) {
                    return verificationURL
                }
            } catch {
                print("Error while getting Verification URL: \(error)")
            }

            sleep(mailpitRetryTimeout)
        }

        return nil
    }

    func getVerificationCode(receiver: String, timestamp: Date) async throws -> String? {
        for _ in 1 ... mailpitRetryCount {
            do {
                if let verificationCode = try await mailpitService.getVerificationCode(receiver: receiver, timestamp: timestamp) {
                    return verificationCode
                }
            } catch {
                print("Error while getting Verification URL: \(error)")
            }

            sleep(mailpitRetryTimeout)
        }

        return nil
    }
}
