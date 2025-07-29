import Foundation

enum SessionType {
    case crossDevice(sessionId: String)
    case legacy(accessId: String)
    case noSession

    func getSessionIdentifier() -> String? {
        var sessionIdentifier: String?

        switch self {
        case let .crossDevice(sessionId):
            sessionIdentifier = sessionId
        case let .legacy(accessId):
            sessionIdentifier = accessId
        case .noSession:
            sessionIdentifier = nil
        }

        return sessionIdentifier
    }
}
