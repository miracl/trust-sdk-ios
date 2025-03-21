import Foundation

/// An enumeration that describes issues with cryptography calculations.
public enum CryptoError: Error, Equatable {
    /// Error while getting client token.
    case getClientTokenError(info: String)

    /// Error while getting client pass1.
    case clientPass1Error(info: String)

    /// Error while getting client pass2.
    case clientPass2Error(info: String)

    /// Error while generating signing key pair.
    case generateSigningKeypairError(info: String)

    /// Error while getting signing client token.
    case getSigningClientToken(info: String)

    /// Error while signing.
    case signError(info: String)
}

extension CryptoError: LocalizedError {
    public var errorDescription: String? {
        var description = ""
        switch self {
        case let .getClientTokenError(info):
            description = NSLocalizedString("\(CryptoError.getClientTokenError(info: info))", comment: "")
        case let .clientPass1Error(info):
            description = NSLocalizedString("\(CryptoError.clientPass1Error(info: info))", comment: "")
        case let .clientPass2Error(info):
            description = NSLocalizedString("\(CryptoError.clientPass1Error(info: info))", comment: "")
        case let .generateSigningKeypairError(info):
            description = NSLocalizedString("\(CryptoError.generateSigningKeypairError(info: info))", comment: "")
        case let .getSigningClientToken(info):
            description = NSLocalizedString("\(CryptoError.getSigningClientToken(info: info))", comment: "")
        case let .signError(info):
            description = NSLocalizedString("\(CryptoError.signError(info: info))", comment: "")
        }
        return description
    }
}

extension CryptoError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .getClientTokenError:
            return 1
        case .clientPass1Error:
            return 2
        case .clientPass2Error:
            return 3
        case .generateSigningKeypairError:
            return 4
        case .getSigningClientToken:
            return 5
        case .signError:
            return 6
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .getClientTokenError(info),
             let .clientPass1Error(info: info),
             let .generateSigningKeypairError(info),
             let .clientPass2Error(info),
             let .getSigningClientToken(info),
             let .signError(info):
            return ["info": info]
        }
    }
}
