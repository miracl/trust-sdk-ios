#if SWIFT_PACKAGE
    import SQLChiper
#else
    import MIRACLTrust.SQLChiper
#endif

import Foundation

class SQLiteMigration2to3: SQLiteMigration {
    var sqliteHelper: SQLiteHelper
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    let updatedDatabaseVersion = 3

    init(sqliteHelper: SQLiteHelper) {
        self.sqliteHelper = sqliteHelper
    }

    func migrate() throws {
        try createNewUsersTable()
        try migrateIdentitiesToUser()
        try dropOldTables()
        try sqliteHelper.setCurrentDatabaseVersion(
            databaseVersion: updatedDatabaseVersion
        )
    }

    private func createNewUsersTable() throws {
        let createUserNewTable = """
            CREATE TABLE IF NOT EXISTS User_new(
                userId TEXT NOT NULL CHECK (length(userId) > 0),
                projectId TEXT NOT NULL CHECK (length(projectId) > 0),
                revoked BOOLEAN NOT NULL,
                dtas TEXT NOT NULL CHECK (length(dtas) > 0),
                mpinId BLOB NOT NULL CHECK (length(mpinId) > 0),
                token BLOB NOT NULL CHECK (length(token) > 0),
                pinLength INTEGER NOT NULL CHECK (pinLength >= 1),
                publicKey BLOB,
                PRIMARY KEY(userId, projectId)
            );
        """
        let result = sqlite3_exec(sqliteHelper.database, createUserNewTable, nil, nil, nil)
        if result != SQLITE_OK {
            throw SQLiteMigrationError.migrationError(errorMessage: getErrorMessage())
        }
    }

    private func migrateIdentitiesToUser() throws {
        let insertIntoUserNewStatement = """
            INSERT INTO User_new (userId, projectId, revoked, pinLength, mpinId, token, dtas, publicKey)
            SELECT
                userId, projectId, revoked, i.pinLength, i.mpinId, i.token, i.dtas, i.publicKey
            FROM User u
            INNER JOIN Identity i WHERE
            CASE WHEN u.signingIdentityId IS NOT NULL THEN i.uuid = u.signingIdentityId
            ELSE i.uuid = u.authenticationIdentityId
            END;
        """

        try sqliteHelper.insert(
            statement: insertIntoUserNewStatement,
            buildBindings: nil
        )
    }

    private func dropOldTables() throws {
        let alterOldTablesStatement = """
            BEGIN TRANSACTION;
            DROP TABLE Identity;
            DROP TABLE User;
            ALTER TABLE User_new RENAME TO User;
            COMMIT;
        """
        let result = sqlite3_exec(sqliteHelper.database, alterOldTablesStatement, nil, nil, nil)
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
