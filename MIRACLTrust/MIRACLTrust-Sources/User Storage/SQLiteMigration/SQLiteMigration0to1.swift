#if SWIFT_PACKAGE
    import SQLChiper
#else
    import MIRACLTrust.SQLChiper
#endif

import Foundation

struct SigningUserMigrationFields {
    var id: Int
    var publicKey: Data
}

class SQLiteMigration0to1: SQLiteMigration {
    var sqliteHelper: SQLiteHelper
    var projectId: String

    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    let newUserVersion = 1

    init(projectId: String, sqliteHelper: SQLiteHelper) {
        self.projectId = projectId
        self.sqliteHelper = sqliteHelper
    }

    func migrate() throws {
        try alterTables()
        try migrateUserTable()
        try migrateSigningUserTable()
        try dropOldTables()
        try sqliteHelper.setCurrentDatabaseVersion(databaseVersion: newUserVersion)
    }

    private func alterTables() throws {
        let alterOldTablesStatement = """
            BEGIN TRANSACTION;

            ALTER TABLE Identity RENAME TO Identity_old;

            CREATE TABLE IF NOT EXISTS Identity(
                uuid TEXT PRIMARY KEY CHECK (length(uuid) > 0),
                dtas TEXT NOT NULL CHECK (length(dtas) > 0),
                mpinId BLOB NOT NULL CHECK (length(mpinId) > 0),
                token BLOB NOT NULL CHECK (length(token) > 0),
                pinLength INTEGER NOT NULL,
                revoked BOOLEAN,
                publicKey BLOB
            );

            ALTER TABLE User RENAME TO User_old;

            CREATE TABLE IF NOT EXISTS User(
                userId TEXT NOT NULL CHECK (length(userId) > 0),
                projectId TEXT NOT NULL CHECK (length(projectId) > 0),
                authenticationIdentityId TEXT NOT NULL CHECK (length(authenticationIdentityId) > 0),
                signingIdentityId TEXT CHECK (length(signingIdentityId) > 0),
                PRIMARY KEY(userId, projectId)
            );

            COMMIT;
        """
        let result = sqlite3_exec(sqliteHelper.database, alterOldTablesStatement, nil, nil, nil)
        if result != SQLITE_OK {
            throw SQLiteMigrationError.migrationError(errorMessage: getErrorMessage())
        }
    }

    func migrateUserTable() throws {
        var ids = [Int]()
        try sqliteHelper.select(
            statement: "SELECT identity_id FROM User_old",
            bindingsBlock: nil,
            bindResultBlock: { statement_tmp in
                let currentId = Int(sqlite3_column_int(statement_tmp, 0))
                ids.append(currentId)
            }
        )

        for givenId in ids {
            let authenticationUserId = NSUUID().uuidString
            let insertIntoIdentityStatement = """
               INSERT INTO Identity (uuid, dtas, mpinId, token, pinLength, revoked)
               SELECT ?, dtas, mpinId, token, pinLength, 0
               FROM Identity_old WHERE Id = ?;
            """

            try sqliteHelper.insert(statement: insertIntoIdentityStatement) { statement_tmp in
                let authenticationUserId = authenticationUserId as NSString
                sqlite3_bind_text(statement_tmp, 1, authenticationUserId.utf8String, -1, nil)
                sqlite3_bind_int(statement_tmp, 2, Int32(givenId))
            }

            let insertIntoUserStatement = """
               INSERT INTO User (userId, projectId, authenticationIdentityId)
               SELECT userId, ?, ?
               FROM Identity_old WHERE Id = ?;
            """

            try sqliteHelper.insert(statement: insertIntoUserStatement) { statement_tmp in
                let projectId = self.projectId as NSString
                sqlite3_bind_text(statement_tmp, 1, projectId.utf8String, -1, nil)

                let authenticationUserId = authenticationUserId as NSString
                sqlite3_bind_text(statement_tmp, 2, authenticationUserId.utf8String, -1, nil)

                sqlite3_bind_int(statement_tmp, 3, Int32(givenId))
            }
        }
    }

    func migrateSigningUserTable() throws {
        var migrationFields = [SigningUserMigrationFields]()
        try sqliteHelper.select(
            statement: "SELECT identity_id, publicKey FROM SigningUser",
            bindingsBlock: nil,
            bindResultBlock: { statement_tmp in

                let currentId = Int(sqlite3_column_int(statement_tmp, 0))
                var publicKey = Data()
                if let pointer = sqlite3_column_blob(statement_tmp, 1) {
                    let size = sqlite3_column_bytes(statement_tmp, 1)
                    publicKey = Data(bytes: pointer, count: Int(size))
                }

                let internalObj = SigningUserMigrationFields(id: currentId, publicKey: publicKey)
                migrationFields.append(internalObj)
            }
        )

        for givenId in migrationFields {
            let uuid = NSUUID().uuidString

            let migratePreviousIdentity = """
               INSERT INTO Identity (uuid, dtas, mpinId, token, pinLength, revoked, publicKey)
               SELECT ?, dtas, mpinId, token, pinLength, 0, ?
               FROM Identity_old WHERE Id = ?;
            """

            try sqliteHelper.insert(statement: migratePreviousIdentity) { statement_tmp in
                let authenticationUserId = uuid as NSString
                sqlite3_bind_text(statement_tmp, 1, authenticationUserId.utf8String, -1, nil)

                _ = givenId.publicKey.withUnsafeBytes {
                    sqlite3_bind_blob(statement_tmp, 2, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
                }

                sqlite3_bind_int(statement_tmp, 3, Int32(givenId.id))
            }

            let migrateSigningUserStatement = """
                UPDATE User
                SET signingIdentityId = ?
                WHERE userId = (SELECT userId FROM Identity_old WHERE id = ?);
            """
            try sqliteHelper.update(statement: migrateSigningUserStatement, buildBindings: { stmt in
                let authenticationUserId = uuid as NSString
                sqlite3_bind_text(stmt, 1, authenticationUserId.utf8String, -1, nil)
                sqlite3_bind_int(stmt, 2, Int32(givenId.id))
            })
        }
    }

    private func dropOldTables() throws {
        let dropTablesStatement = """
           BEGIN TRANSACTION;
               DROP TABLE Identity_old;
               DROP TABLE SigningUser;
               DROP TABLE User_old;
           COMMIT;
        """
        let result = sqlite3_exec(sqliteHelper.database, dropTablesStatement, nil, nil, nil)
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
