@testable import MIRACLTrust
import XCTest

enum BackupException: Error {
    case backupFailed
}

final class MockBackupConfigurable: BackupConfigurable {
    let backupThrowException: Bool

    init(backupThrowException: Bool) {
        self.backupThrowException = backupThrowException
    }

    func excludeFromBackup(url _: inout URL) throws {
        if backupThrowException {
            throw BackupException.backupFailed
        }
    }
}

final class MockFileManager: FileManagerProtocol {
    func createDirectory(at _: URL, withIntermediateDirectories _: Bool, attributes _: [FileAttributeKey: Any]?) throws {}

    func urls(for _: FileManager.SearchPathDirectory, in _: FileManager.SearchPathDomainMask) -> [URL] {
        []
    }

    func fileExists(atPath _: String) -> Bool {
        true
    }
}

class DeviceTagManagerTests: XCTestCase {
    let logger = DefaultLogger(level: .none)
    var backupConfigurator = MockBackupConfigurable(backupThrowException: false)
    var mockFileManager = MockFileManager()

    override func setUpWithError() throws {
        try super.setUpWithError()

        DeviceTagManager.cachedTag = nil

        try deleteSDKDirectory()
        backupConfigurator = MockBackupConfigurable(backupThrowException: false)
        mockFileManager = MockFileManager()
    }

    func testDeviceTagCreation() {
        let deviceTagManager = DeviceTagManager(logger: logger)
        let newlyCreatedDeviceTag = deviceTagManager.deviceTag
        XCTAssertNotNil(newlyCreatedDeviceTag)
        XCTAssertEqual(newlyCreatedDeviceTag.count, 32)
    }

    func testDeviceTagCreationAndFetch() {
        let deviceTagManager = DeviceTagManager(logger: logger)
        let deviceTag = deviceTagManager.deviceTag

        DeviceTagManager.cachedTag = nil

        let deviceTagManagerFromFile = DeviceTagManager(logger: logger)
        let deviceTagFromFile = deviceTagManagerFromFile.deviceTag

        XCTAssertEqual(deviceTag, deviceTagFromFile)
        XCTAssertEqual(deviceTag.count, 32)
    }

    func testDeviceTagBackupFails() {
        backupConfigurator = MockBackupConfigurable(backupThrowException: true)

        let deviceTagManager = DeviceTagManager(logger: logger, backupConfigurator: backupConfigurator)
        let deviceTag = deviceTagManager.deviceTag

        let secondDeviceTagManager = DeviceTagManager(logger: logger)
        let secondDeviceTag = secondDeviceTagManager.deviceTag

        XCTAssertEqual(secondDeviceTag, deviceTag)
    }

    func testDeviceTagFailedApplicationSupportDirectoryFetch() {
        let mockFileManager = MockFileManager()
        let deviceTagManager = DeviceTagManager(logger: logger, fileManager: mockFileManager)
        let deviceTag = deviceTagManager.deviceTag

        DeviceTagManager.cachedTag = nil

        let secondDeviceTagManager = DeviceTagManager(logger: logger)
        let secondDeviceTag = secondDeviceTagManager.deviceTag

        XCTAssertNotEqual(secondDeviceTag, deviceTag)
    }

    func testDeviceTagGetCachedTag() throws {
        let deviceTagManager = DeviceTagManager(logger: logger)
        let newlyCreatedDeviceTag = deviceTagManager.deviceTag
        XCTAssertNotNil(newlyCreatedDeviceTag)
        XCTAssertEqual(newlyCreatedDeviceTag.count, 32)

        try deleteSDKDirectory()

        let cachedDeviceTag = deviceTagManager.deviceTag
        XCTAssertEqual(cachedDeviceTag, newlyCreatedDeviceTag)
    }

    // MARK: Private

    private func deleteSDKDirectory() throws {
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let miraclSDKDirectory = "com.miracl.ios.sdk"
        let sdkDirectory = appSupportDir.appendingPathComponent(miraclSDKDirectory)

        if FileManager.default.fileExists(atPath: sdkDirectory.path) {
            try FileManager.default.removeItem(at: sdkDirectory)
        }
    }
}
