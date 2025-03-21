import MIRACLTrust
import XCTest

@objc class GmailServiceTestWrapper: NSObject {
    let gmailService = GmailService()

    private let gmailRetryCount = 60
    private let gmailRetryTimeout: UInt32 = 10

    func getVerificationURL(
        receiver: String,
        timestamp: Date
    ) async throws -> URL? {
        for _ in 1 ... gmailRetryCount {
            do {
                if let verificationURL = try await gmailService.getVerificationURL(receiver: receiver, timestamp: timestamp) {
                    return verificationURL
                }
            } catch {
                print("Error while getting Verification URL: \(error)")
            }

            sleep(gmailRetryTimeout)
        }

        return nil
    }

    func getVerificationCode(receiver: String, timestamp: Date) async throws -> String? {
        for _ in 1 ... gmailRetryCount {
            do {
                if let verificationCode = try await gmailService.getVerificationCode(receiver: receiver, timestamp: timestamp) {
                    return verificationCode
                }
            } catch {
                print("Error while getting Verification URL: \(error)")
            }

            sleep(gmailRetryTimeout)
        }

        return nil
    }
}
