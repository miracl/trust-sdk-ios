import MIRACLTrust

struct CrossDeviceSessionAbortCase {
    func abortCrossDeviceSession(_ crossDeviceSession: CrossDeviceSession) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            MIRACLTrust.getInstance().abortCrossDeviceSession(crossDeviceSession: crossDeviceSession) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: result)
            }
        }
    }
}
