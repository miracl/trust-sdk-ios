import Foundation

enum StorageType {
    case `default`(DefaultUserStorageOptions)
    case custom(UserStorage)
}
