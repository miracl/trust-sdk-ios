import Foundation

final class PinController: Sendable {
    private nonisolated(unsafe) var userEnteredPin: String?
    private let accessQueue = DispatchQueue(label: "com.miracl.pinSyncQueue")

    func updatePin(_ newPin: String?) {
        accessQueue.sync {
            self.userEnteredPin = newPin
        }
    }

    func readPin() -> String? {
        var pin: String?
        accessQueue.sync {
            pin = self.userEnteredPin
        }
        return pin
    }
}
