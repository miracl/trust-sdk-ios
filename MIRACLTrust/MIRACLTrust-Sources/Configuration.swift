import Foundation

/// An object that stores configurations of the SDK with values issued by MIRACL Trust.
@objc public class Configuration: NSObject {
    /// Identifier of the project in the MIRACL Trust platform.
    var projectId: String?

    /// Base URL of the MIRACL Trust platform.
    var projectURL: URL

    /// URL Session configuration object. Use this when you want to set the custom configuration to the SDK's instance of URLSession.
    /// As a default value, it uses `ephemeral` configuration, 30 seconds for `timeoutIntervalForRequest`, and
    /// 300 seconds for `timeoutIntervalForResource`.
    var urlSessionConfiguration: URLSessionConfiguration

    /// Device name. Identifier of the device shown in the MIRACL Trust portal.
    var deviceName: String

    /// Logging contract implementation.
    var logger: Logger?

    /// Logging enabled. This value is used only in the default message writer implementation, otherwise it is ignored.
    var loggingLevel: LoggingLevel

    /// Additional information that will be sent via the `X-MIRACL-CLIENT` HTTP header.
    var applicationInfo: String?

    /// Type of the storage that could be configured.
    var storageType: StorageType

    override private init() {
        projectId = nil
        projectURL = URL(string: MIRACL_API_URL)!
        applicationInfo = nil

        urlSessionConfiguration = URLSessionConfiguration.ephemeral
        urlSessionConfiguration.timeoutIntervalForRequest = 30
        urlSessionConfiguration.timeoutIntervalForResource = 300
        deviceName = ""
        loggingLevel = .none
        storageType = .default(DefaultUserStorageOptions())
    }

    override public var description: String {
        "Configuration(projectId: \(String(describing: projectId)), projectURL: \(projectURL), deviceName: \(deviceName), applicationInfo: \(String(describing: applicationInfo)), urlSessionConfiguration: \(urlSessionConfiguration), logger: \(String(describing: logger)), loggingLevel: \(loggingLevel), storageType: \(storageType))"
    }

    /// Builds ``Configuration`` objects.
    @objc(ConfigurationBuilder) public class Builder: NSObject {
        private var configurationToBuild = Configuration()
        private let projectURL: String

        ///  Initializes the ``Configuration/Builder`` object.
        /// - Parameters:
        ///   - projectId: `Project ID` setting for the MIRACL Trust platform.
        ///   - projectURL: `Project URL` setting for the MIRACL Trust platform.
        ///   - deviceName: identifier used to find the device in the MIRACL Trust Portal.
        ///   If not provided, the value of `deviceName` defaults to the operating system name (e.g., `iOS`).
        @objc public init(
            projectId: String,
            projectURL: String = MIRACL_API_URL,
            deviceName: String? = nil
        ) {
            configurationToBuild.projectId = projectId.trimmingCharacters(in: .whitespacesAndNewlines)
            self.projectURL = projectURL

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

        @_spi(MIRACLTrustAuthenticatorApi)
        override public init() {
            projectURL = MIRACL_API_URL
            #if os(iOS)
                configurationToBuild.deviceName = "iOS"
            #elseif os(watchOS)
                configurationToBuild.deviceName = "watchOS"
            #else
                configurationToBuild.deviceName = ""
            #endif
        }

        ///  Sets ``DefaultStorageOptions``.
        ///
        ///  The default storage is an encrypted SQLite database in the `documents` directory.
        ///
        /// - Parameter closure: A closure receiving an inout ``DefaultUserStorageOptions`` instance,
        ///   allowing you to modify its properties. Changes made in the closure
        ///   are applied to the user storage setup.
        /// - Returns: the ``Configuration.Builder`` object.
        @discardableResult
        public func configureDefaultUserStorage(
            _ closure: (inout DefaultUserStorageOptions) -> Void
        ) -> Builder {
            var options = DefaultUserStorageOptions()
            closure(&options)

            configurationToBuild.storageType = .default(options)

            return self
        }

        /// Sets the custom ``UserStorage`` implementation.
        /// - Parameter userStorage: custom ``UserStorage`` implementation.
        /// - Returns: the ``Configuration.Builder`` object.
        @discardableResult public func userStorage(
            userStorage: UserStorage
        ) -> Builder {
            configurationToBuild.storageType = .custom(userStorage)
            return self
        }

        /// Sets the value of the device name.
        /// - Parameter deviceName: device name
        /// - Returns: the ``Configuration.Builder`` object.
        @objc(deviceNameWith:) @discardableResult public func deviceName(
            deviceName: String
        ) -> Builder {
            configurationToBuild.deviceName = deviceName
            return self
        }

        /// Sets the custom ``Logger`` writer implementation.
        /// - Parameter logger: custom ``Logger`` implementation.
        /// - Returns: the ``Configuration.Builder`` object.
        @objc(loggerWith:) @discardableResult public func logger(
            logger: Logger
        ) -> Builder {
            configurationToBuild.logger = logger
            return self
        }

        /// Sets the custom ``LoggingLevel`` value. By default, it is ``LoggingLevel/none``.
        /// This level can be set only for the default logger, otherwise it will be ignored.
        /// - Parameter level: custom ``LoggingLevel``
        /// - Returns: the ``Configuration.Builder`` object.
        @objc(loggingLevelWith:) @discardableResult public func loggingLevel(
            level: LoggingLevel
        ) -> Builder {
            configurationToBuild.loggingLevel = level
            return self
        }

        /// Sets the additional application information that will be sent via the X-MIRACL-CLIENT HTTP header.
        /// - Parameter applicationInfo: application info.
        /// - Returns: the ``Configuration.Builder`` object.
        @objc(applicationInfoWith:) @discardableResult public func applicationInfo(
            applicationInfo: String
        ) -> Builder {
            configurationToBuild.applicationInfo = applicationInfo
            return self
        }

        ///  Applies the custom configuration to the SDK's instance of URLSession.
        ///  By default, it uses an `ephemeral` configuration with a 30-second `timeoutIntervalForRequest` and
        ///  a 300-second `timeoutIntervalForResource`.
        ///
        /// - Parameter urlSessionConfiguration: configuration for the URLSession to be set.
        /// - Returns: the ``Configuration.Builder`` object.
        @objc(URLSessionConfigurationWith:) @discardableResult public func URLSessionConfiguration(
            urlSessionConfiguration: URLSessionConfiguration
        ) -> Builder {
            configurationToBuild.urlSessionConfiguration = urlSessionConfiguration
            return self
        }

        /// Returns the ``Configuration`` object.
        /// - Throws: ``ConfigurationError``.
        /// - Returns: the ``Configuration`` object.
        @objc public func build() throws -> Configuration {
            if let projectId = configurationToBuild.projectId, projectId.isEmpty {
                throw ConfigurationError.emptyProjectId
            }

            guard let projectURL = URL(string: projectURL) else {
                throw ConfigurationError.invalidProjectURL
            }

            configurationToBuild.projectURL = projectURL

            return configurationToBuild
        }
    }
}
