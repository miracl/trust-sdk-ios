import Foundation

/// Object that stores configurations of the SDK with values issued by MIRACL.
/// - Tag: Configuration
@objc public class Configuration: NSObject {
    /// Identifier of the project in the MIRACL Trust platform.
    var projectId: String

    /// Base URL of the MIRACL platform.
    var platformURL: URL

    /// URL Session configuration object. Use this when you want to set the custom configuration to the SDK's instance of URLSession.
    /// As a default value it uses `ephemeral` configuration, 30 seconds for `timeoutIntervalForRequest` and
    /// 300 seconds for `timeoutIntervalForResource`.
    var urlSessionConfiguration: URLSessionConfiguration

    /// Device name. Identifier of device shown in the MIRACL portal.
    var deviceName: String

    /// Logging contract implementation.
    var logger: Logger?

    /// Logging enabled. This value is used only in the default message writer implementation, otherwise is ignored.
    var loggingLevel: LoggingLevel

    // Additional information that will be sent via `X-MIRACL-CLIENT` HTTP header.
    var applicationInfo: String?

    /// Type of the storage that could be configured.
    var storageType: StorageType

    override private init() {
        projectId = ""
        platformURL = MIRACL_API_URL
        applicationInfo = nil

        urlSessionConfiguration = URLSessionConfiguration.ephemeral
        urlSessionConfiguration.timeoutIntervalForRequest = 30
        urlSessionConfiguration.timeoutIntervalForResource = 300
        deviceName = ""
        loggingLevel = .none
        storageType = .default(DefaultUserStorageOptions())
    }

    /// Builds ``Configuration`` objects.
    @objc(ConfigurationBuilder) public class Builder: NSObject {
        private var configurationToBuild = Configuration()

        ///  Initializing ``Configuration/Builder`` object.
        /// - Parameters:
        ///   - projectId: `Project ID` setting for the MIRACL Platform.
        ///   - deviceName: identifier that can help find the device on the MIRACL Trust Portal.
        ///   If not provided,  the value of `deviceName` is the name of the operation system (e.g `iOS`).
        @objc public init(
            projectId: String,
            deviceName: String? = nil
        ) {
            configurationToBuild.projectId = projectId.trimmingCharacters(in: .whitespacesAndNewlines)
            if let deviceName {
                configurationToBuild.deviceName = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                #if os(iOS)
                    configurationToBuild.deviceName = "iOS"
                #elseif os(watchOS)
                    configurationToBuild.deviceName = "watchOS"
                #else
                    configurationToBuild.deviceName = ""
                #endif
            }
        }

        ///  Sets ``DefaultStorageOptions``.
        ///
        ///  The default storage is and encrypted SQLite database stored in the `documents` directory.
        ///
        /// - Parameter closure: A closure that receives an inout ``DefaultUserStorageOptions`` instance
        ///   so you can modify its properties. Any changes you make inside the closure
        ///   are applied to the user storage setup.
        /// - Returns: ``Configuration/Builder`` object.
        @discardableResult
        public func configureDefaultUserStorage(
            _ closure: (inout DefaultUserStorageOptions) -> Void
        ) -> Builder {
            var options = DefaultUserStorageOptions()
            closure(&options)

            configurationToBuild.storageType = .default(options)

            return self
        }

        /// Set custom ``UserStorage`` implementation.
        /// - Parameter userStorage: custom ``UserStorage`` implementation.
        /// - Returns: Configuration.Builder object.
        @discardableResult public func userStorage(
            userStorage: UserStorage
        ) -> Builder {
            configurationToBuild.storageType = .custom(userStorage)
            return self
        }

        /// Sets value of device name.
        /// - Parameter deviceName: device name
        /// - Returns: Configuration.Builder object.
        @objc(deviceNameWith:) @discardableResult public func deviceName(
            deviceName: String
        ) -> Builder {
            configurationToBuild.deviceName = deviceName
            return self
        }

        /// Set custom ``Logger`` writer implementation.
        /// - Parameter logger: custom ``Logger`` implementation.
        /// - Returns: Configuration.Builder object.
        @objc(loggerWith:) @discardableResult public func logger(
            logger: Logger
        ) -> Builder {
            configurationToBuild.logger = logger
            return self
        }

        /// Sets custom ``LoggingLevel`` value. By default it is ``LoggingLevel/none``.
        /// This level can be set only for default logger, otherwise will be ignored.
        /// - Parameter level: custom ``LoggingLevel``
        /// - Returns: Configuration.Builder object.
        @objc(loggingLevelWith:) @discardableResult public func loggingLevel(
            level: LoggingLevel
        ) -> Builder {
            configurationToBuild.loggingLevel = level
            return self
        }

        /// Sets custom MIRACL platform URL.
        /// - Parameter url: custom MIRACL platform URL.
        /// - Returns: Configuration.Builder object.
        @objc(platformURLWith:) @discardableResult public func platformURL(
            url: URL
        ) -> Builder {
            configurationToBuild.platformURL = url
            return self
        }

        /// Sets additional application information that will be sent via X-MIRACL-CLIENT HTTP header.
        /// - Parameter applicationInfo: application info.
        /// - Returns: Configuration.Builder object.
        @objc(applicationInfoWith:) @discardableResult public func applicationInfo(
            applicationInfo: String
        ) -> Builder {
            configurationToBuild.applicationInfo = applicationInfo
            return self
        }

        ///  Use this when you want to set the custom configuration to the SDK's instance of URLSession.
        ///  As a default value it uses `ephemeral` configuration, 30 seconds for `timeoutIntervalForRequest` and
        ///  300 seconds for `timeoutIntervalForResource`.
        ///
        /// - Parameter urlSessionConfiguration: configuration for the URLSession to be set.
        /// - Returns: Configuration.Builder object.
        @objc(URLSessionConfigurationWith:) @discardableResult public func URLSessionConfiguration(
            urlSessionConfiguration: URLSessionConfiguration
        ) -> Builder {
            configurationToBuild.urlSessionConfiguration = urlSessionConfiguration
            return self
        }

        /// Returns ``Configuration`` object.
        /// - Throws: ``ConfigurationError``.
        /// - Returns: ``Configuration`` object.
        @objc public func build() throws -> Configuration {
            if configurationToBuild.projectId.isEmpty {
                throw ConfigurationError.configurationEmptyProjectId
            }

            return configurationToBuild
        }
    }
}
