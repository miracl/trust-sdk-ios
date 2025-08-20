import Foundation

/// Configurable options for the default storage provided by MIRACL Trust iOS SDK.
///
/// The default storage that MIRACL Trust iOS SDK provides is an encrypted SQLite database stored at the `documents` directory.
public class DefaultUserStorageOptions {
    /// Name of the storage file.
    public var storageName: String = "miracl"

    /// File system path used for default storage file.
    public var directoryURL: URL?

    /// [Keychain access group](https://developer.apple.com/documentation/security/sharing-access-to-keychain-items-among-a-collection-of-apps) identifier used to share a storage key between applications from the same company.
    public var keychainAccessGroup: String?
}
