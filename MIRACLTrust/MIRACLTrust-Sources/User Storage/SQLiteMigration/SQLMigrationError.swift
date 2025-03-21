enum SQLiteMigrationError: Error, Equatable {
    case migrationError(errorMessage: String?)
    case versionError
}
