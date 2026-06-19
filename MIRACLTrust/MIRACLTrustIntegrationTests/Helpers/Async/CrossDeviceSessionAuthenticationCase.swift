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

        return try await withCheckedThrowingContinuation { continuation in
            MIRACLTrust.getInstance().authenticateCrossDeviceSession(
                crossDeviceSession: crossDeviceSession,
                user: user,
                didRequestPinHandler: pinHandler
            ) { isAuthenticated, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: isAuthenticated)
            }
        }
    }
}
