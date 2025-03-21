enum SQLiteDefaultStorageError: Error, Equatable {
    case noDir
    case noConnection
    case sqliteQueryError(message: String?)
    case prepareStatementError(message: String?)
    case emptyOrNullParametersError
    case encryptionError
    case encryptionKeyUpdateError
}
