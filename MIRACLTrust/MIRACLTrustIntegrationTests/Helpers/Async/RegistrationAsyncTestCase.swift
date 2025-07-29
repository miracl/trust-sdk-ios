import MIRACLTrust

struct RegistrationAsyncTestCase {
    var pinCode: String? = ""

    func register(
        userId: String,
        activationToken: String
    ) async throws -> User {
        let pinCode = pinCode
        let pinHandler: PinRequestHandler = { pinProcessor in
            pinProcessor(pinCode)
        }

        let user: User = try await withCheckedThrowingContinuation { continuation in
            MIRACLTrust.getInstance().register(
                for: userId,
                activationToken: activationToken,
                didRequestPinHandler: pinHandler
            ) { user, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let user {
                    continuation.resume(returning: user)
                }
            }
        }

        return user
    }
}
