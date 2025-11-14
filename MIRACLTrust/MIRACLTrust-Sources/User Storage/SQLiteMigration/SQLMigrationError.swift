enum SQLiteMigrationError: Error, Equatable, DefaultLocalizedError {
    case migrationError(errorMessage: String?)
    case versionError
}
