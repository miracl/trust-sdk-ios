protocol SQLiteMigration {
    var sqliteHelper: SQLiteHelper { get }
    func migrate() throws
}
