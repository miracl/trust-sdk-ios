#if SWIFT_PACKAGE
    import SQLChiper
#else
    import MIRACLTrust.SQLChiper
#endif

import Foundation

class SQLiteMigration1to2: SQLiteMigration {
    var sqliteHelper: SQLiteHelper

    let updatedDatabaseVersion = 2

    init(sqliteHelper: SQLiteHelper) {
        self.sqliteHelper = sqliteHelper
    }

    func migrate() throws {
        try removeRevokedFlagFromIdentityTable()
        try addRevokedFlagToUserTable()
        try sqliteHelper.setCurrentDatabaseVersion(
            databaseVersion: updatedDatabaseVersion
        )
    }

    func removeRevokedFlagFromIdentityTable() throws {
        let alterAuthenticationIdentityTable = """
            ALTER TABLE Identity DROP COLUMN revoked;
        """

        let result = sqlite3_exec(
            sqliteHelper.database,
            alterAuthenticationIdentityTable, nil, nil, nil
        )

        if result != SQLITE_OK {
            throw SQLiteMigrationError.migrationError(errorMessage: getErrorMessage())
        }
    }

    func addRevokedFlagToUserTable() throws {
        let alterAuthenticationIdentityTable = """
            ALTER TABLE User ADD COLUMN revoked BOOLEAN NOT NULL default 0;
        """

        let result = sqlite3_exec(
            sqliteHelper.database,
            alterAuthenticationIdentityTable, nil, nil, nil
        )

        if result != SQLITE_OK {
            throw SQLiteMigrationError.migrationError(errorMessage: getErrorMessage())
        }
    }

    private func getErrorMessage() -> String? {
        if let errorPointer = sqlite3_errmsg(sqliteHelper.database) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        }

        return nil
    }
}
