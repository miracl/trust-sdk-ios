/// Enumeration describing status of the signing session.
@objc public enum SigningSessionStatus: Int, Codable, Sendable {
    // Session is active
    case active

    // Session is finished with signing of transaction.
    case signed

    /// Converts string to `SigningSessionStatus`
    /// - Parameter string: string to convert.
    /// - Returns: SigningSessionStatus from string value.
    static func signingSessionStatus(
        from string: String
    ) -> SigningSessionStatus {
        switch string {
        case "active":
            return .active
        case "signed":
            return .signed
        default:
            return .active
        }
    }
}
