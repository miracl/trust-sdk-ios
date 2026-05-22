import Foundation

final class DeviceTagManager: Sendable {
    init(
        logger: Logger,
        fileManager: FileManagerProtocol = FileManager.default,
        backupConfigurator: BackupConfigurable = DefaultBackupConfigurator()
    ) {
        self.logger = logger
        self.fileManager = fileManager
        backupConfiguration = backupConfigurator
    }

    let logger: Logger
    let fileManager: FileManagerProtocol
    let backupConfiguration: BackupConfigurable
    let miraclDeviceTagFileName = "miracl_device_tag.txt"
    let miraclSDKDirectory = "com.miracl.ios.sdk"

    nonisolated(unsafe) static var cachedTag: String?
    static let queue = DispatchQueue(label: "com.miracl.ios.sdk.deviceTagQueue")

    var deviceTag: String {
        DeviceTagManager.queue.sync {
            if let cachedTag = DeviceTagManager.cachedTag {
                return cachedTag
            }

            if let deviceTag = getFromFile() {
                logger.debug(message: "Getting existing device tag = \(deviceTag)", category: .deviceTag)
                return deviceTag
            }

            let newTag = generate()
            saveToFile(deviceTag: newTag)
            DeviceTagManager.cachedTag = newTag
            return newTag
        }
    }

    private func generate() -> String {
        let bytes = (0 ..< 16).map { _ in UInt8.random(in: 0 ... 255) }
        return Data(bytes).hex
    }

    private func getFromFile() -> String? {
        guard let fileURL = getTagFileURL() else { return nil }
        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    private func saveToFile(deviceTag: String) {
        guard var sdkDirectory = getTagFileURL() else {
            return
        }

        do {
            logger.debug(message: "Saving device tag to file = \(deviceTag)", category: .deviceTag)
            if let data = deviceTag.data(using: .utf8) {
                try data.write(to: sdkDirectory, options: .atomic)
                try backupConfiguration.excludeFromBackup(url: &sdkDirectory)
            } else {
                logger.debug(message: "Device tag is empty or nil", category: .deviceTag)
            }
        } catch {
            logger.debug(message: "Cannot save device tag to file = \(error)", category: .deviceTag)
        }
    }

    private func getTagFileURL() -> URL? {
        guard let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            logger.debug(message: "Application support directory doesn't exist", category: .deviceTag)
            return nil
        }

        let sdkDirectory = appSupportDir.appendingPathComponent(miraclSDKDirectory)

        if !fileManager.fileExists(atPath: sdkDirectory.path) {
            do {
                try fileManager.createDirectory(at: sdkDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logger.debug(message: "Cannot create SDK directory", category: .deviceTag)
                return nil
            }
        }

        return sdkDirectory.appendingPathComponent(miraclDeviceTagFileName)
    }
}
