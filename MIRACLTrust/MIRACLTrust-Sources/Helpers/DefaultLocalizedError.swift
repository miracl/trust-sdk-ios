import Foundation

protocol DefaultLocalizedError: LocalizedError {}

extension DefaultLocalizedError {
    public var errorDescription: String? {
        String(describing: self)
    }
}
