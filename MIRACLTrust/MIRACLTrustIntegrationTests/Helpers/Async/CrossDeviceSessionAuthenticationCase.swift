import MIRACLTrust

struct CrossDeviceSessionAuthenticationCase {
    var pinCode: String? = ""

    func authenticate(
        user: User,
        crossDeviceSession: CrossDeviceSession
    ) async throws -> Bool {
        let pinCode = pinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        let isAuthenticated: Bool = try await withCheckedThrowingContinuation { continuation in
            MIRACLTrust.getInstance()._authenticate(user: user, crossDeviceSession: crossDeviceSession, didRequestPinHandler: pinHandler, completionHandler: { isAuthenticated, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: isAuthenticated)
            })
        }

        return isAuthenticated
    }
}
