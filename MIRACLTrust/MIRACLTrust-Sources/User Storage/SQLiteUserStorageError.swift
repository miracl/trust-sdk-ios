import Foundation

/// An enumeration that describes issues with the default user storage.
enum SQLiteUserStorageError: Error {
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

extension SQLiteUserStorageError: LocalizedError {
    var errorDescription: String? {
        var description = ""
        switch self {
        case .documentsDirectoryMissing:
            description = NSLocalizedString("\(SQLiteUserStorageError.documentsDirectoryMissing)", comment: "")
        case .noConnection:
            description = NSLocalizedString("\(SQLiteUserStorageError.noConnection)", comment: "")
        case let .sqliteQueryError(message: message):
            description = NSLocalizedString("\(SQLiteUserStorageError.sqliteQueryError(message: message))", comment: "")
        case let .prepareStatementError(message: message):
            description = NSLocalizedString("\(SQLiteUserStorageError.prepareStatementError(message: message))", comment: "")
        case .encryptionKeyConfigurationError:
            description = NSLocalizedString("\(SQLiteUserStorageError.encryptionKeyConfigurationError)", comment: "")
        case .encryptionKeyUpdateAccessibilityError:
            description = NSLocalizedString("\(SQLiteUserStorageError.encryptionKeyUpdateAccessibilityError)", comment: "")
        case .accessGroupUpdateError:
            description = NSLocalizedString("\(SQLiteUserStorageError.accessGroupUpdateError)", comment: "")
        }
        return description
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
