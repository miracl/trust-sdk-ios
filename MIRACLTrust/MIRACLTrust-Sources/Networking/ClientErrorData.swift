import Foundation

/// Client error representation which is returned by the MIRACL API.
@objcMembers
@objc public final class ClientErrorData: NSObject, Sendable {
    /// Code of the error.
    public let code: String

    /// Human readable representation of the error.
    public let info: String

    /// Additional information received in the error response.
    public let context: [String: String]?

    init(code: String, info: String, context: [String: String]?) {
        self.code = code
        self.info = info
        self.context = context
    }
}
