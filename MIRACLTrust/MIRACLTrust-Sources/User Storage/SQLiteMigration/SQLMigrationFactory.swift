class SQLMigrationFactory {
    class func migrations(
        projectId: String,
        sqliteHelper: SQLiteHelper,
        from: Int,
        to: Int
    ) throws -> [SQLiteMigration] {
        var migrations = [SQLiteMigration]()
        var version = from
        if version == 0, version != to {
            migrations.append(SQLiteMigration0to1(projectId: projectId, sqliteHelper: sqliteHelper))
            version += 1
        }

        if version == 1, version != to {
            migrations.append(SQLiteMigration1to2(sqliteHelper: sqliteHelper))
            version += 1
        }

        if version == 2, version != to {
            migrations.append(SQLiteMigration2to3(sqliteHelper: sqliteHelper))
        }

        return migrations
    }
}
