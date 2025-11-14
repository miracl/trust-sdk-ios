import Foundation

/// An enumeration that describes issues with the default user storage.
enum SQLiteUserStorageError: Error, DefaultLocalizedError {
    /// There is no documents directory in the application.
    case documentsDirectoryMissing

    /// Could not open database connection to the default storage.
    case noConnection

    /// Problem with querying the SQL storage.
    case sqliteQueryError(message: String?)

    /// Problem when preparing SQL statement.
    case prepareStatementError(message: String?)

    /// There is an error when configuring an encryption key.
    case encryptionKeyConfigurationError

    /// Could not update encryption key accessibility.
    case encryptionKeyUpdateAccessibilityError

    /// Could not add access group to the encryption key of the storage.
    case accessGroupUpdateError
}

extension SQLiteUserStorageError: Equatable {
    static func == (
        lhs: SQLiteUserStorageError,
        rhs: SQLiteUserStorageError
    ) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension SQLiteUserStorageError: CustomNSError {
    var errorCode: Int {
        switch self {
        case .documentsDirectoryMissing:
            1
        case .noConnection:
            2
        case .sqliteQueryError:
            3
        case .prepareStatementError:
            4
        case .encryptionKeyConfigurationError:
            5
        case .encryptionKeyUpdateAccessibilityError:
            6
        case .accessGroupUpdateError:
            7
        }
    }

    var errorUserInfo: [String: Any] {
        switch self {
        case let .sqliteQueryError(message), let .prepareStatementError(message):
            if let message {
                return ["message": message]
            } else {
                return [String: Any]()
            }
        default:
            return [String: Any]()
        }
    }
}
