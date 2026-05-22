import Foundation

protocol BackupConfigurable: Sendable {
    func excludeFromBackup(url: inout URL) throws
}

final class DefaultBackupConfigurator: BackupConfigurable {
    func excludeFromBackup(url: inout URL) throws {
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }
}
