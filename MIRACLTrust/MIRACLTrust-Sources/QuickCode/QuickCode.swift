import Foundation

@objcMembers
@objc public final class QuickCode: NSObject, Sendable {
    public let code: String
    public let expireTime: Date
    public let ttlSeconds: Int

    init(
        code: String,
        expireTime: Date,
        ttlSeconds: Int
    ) {
        self.code = code
        self.expireTime = expireTime
        self.ttlSeconds = ttlSeconds
    }
}
