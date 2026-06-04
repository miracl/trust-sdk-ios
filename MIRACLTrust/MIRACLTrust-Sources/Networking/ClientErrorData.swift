import Foundation

/// A client error representation which is returned by the MIRACL Trust API.
@objcMembers
@objc public final class ClientErrorData: NSObject, Sendable {
    /// Code of the error.
    public let code: String

    /// Human-readable representation of the error.
    public let info: String

    /// Additional information in the error response.
    public let context: [String: String]?

    init(code: String, info: String, context: [String: String]?) {
        self.code = code
        self.info = info
        self.context = context
    }

    override public var description: String {
        "ClientErrorData(code: \(code), info: \(info), context: \(String(describing: context)))"
    }
}
