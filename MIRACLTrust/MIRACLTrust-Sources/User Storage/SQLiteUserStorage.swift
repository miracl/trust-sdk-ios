#if SWIFT_PACKAGE
    import SQLChiper
#else
    import MIRACLTrust.SQLChiper
#endif

import Foundation

final class SQLiteUserStorage: NSObject, UserStorage {
    let databaseName: String
    let projectId: String
    let sqliteHelper = SQLiteHelper()

    init(
        projectId: String,
        databaseName: String = "miracl"
    ) {
        self.projectId = projectId
        self.databaseName = databaseName
    }

    // Current version of the SQLite database
    let requestedDatabaseVersion = 3
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    func loadStorage() throws {
        let directoryURL = try sqliteHelper.getDocumentsDirectory()
        let dbFileURL = directoryURL
            .appendingPathComponent("\(databaseName).sqlite")
        let isDatabaseExist = FileManager.default.fileExists(atPath: dbFileURL.path)

        try sqliteHelper.openDatabaseConnection(for: databaseName)
        try sqliteHelper.encryptDatabase()

        let currentDatabaseVersion = try sqliteHelper.getCurrentDatabaseVersion()
        if sqliteHelper.isMigrationNeeded(
            currentDatabaseVersion: currentDatabaseVersion,
            requestedDatabaseVersion: requestedDatabaseVersion
        ), isDatabaseExist {
            let migrations = try SQLMigrationFactory.migrations(
                projectId: projectId,
                sqliteHelper: sqliteHelper,
                from: currentDatabaseVersion,
                to: requestedDatabaseVersion
            )

            for migration in migrations {
                try migration.migrate()
            }

        } else {
            let createUserTable = """
                CREATE TABLE IF NOT EXISTS User(
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

            try sqliteHelper.createTable(with: createUserTable)
            try sqliteHelper.setCurrentDatabaseVersion(
                databaseVersion: requestedDatabaseVersion
            )
        }
    }

    func add(user: User) throws {
        let insertUser = """
            INSERT INTO
                User(userId, projectId, revoked, pinLength, mpinId, token, dtas, publicKey) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """

        try sqliteHelper.insert(
            statement: insertUser
        ) { insertStatement in

            let userId = user.userId as NSString
            sqlite3_bind_text(insertStatement, 1, userId.utf8String, -1, nil)

            let projectId = user.projectId as NSString
            sqlite3_bind_text(insertStatement, 2, projectId.utf8String, -1, nil)

            let revoked = user.revoked as NSNumber
            sqlite3_bind_int(insertStatement, 3, revoked.int32Value)

            let pinLength = user.pinLength as NSNumber
            sqlite3_bind_int(insertStatement, 4, pinLength.int32Value)

            _ = user.mpinId.withUnsafeBytes {
                sqlite3_bind_blob(insertStatement, 5, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
            }

            _ = user.token.withUnsafeBytes {
                sqlite3_bind_blob(insertStatement, 6, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
            }

            let dtas = user.dtas as NSString
            sqlite3_bind_text(insertStatement, 7, dtas.utf8String, -1, nil)

            if let publicKey = user.publicKey {
                _ = publicKey.withUnsafeBytes {
                    sqlite3_bind_blob(insertStatement, 8, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
                }
            }
        }
    }

    func delete(user: User) throws {
        let deleteUser = """
            DELETE FROM User WHERE userId = ? AND projectId = ?
        """

        try sqliteHelper.delete(
            statement: deleteUser,
            buildBindings: { statement in
                let userId = user.userId as NSString
                sqlite3_bind_text(statement, 1, userId.utf8String, -1, nil)

                let projectId = user.projectId as NSString
                sqlite3_bind_text(statement, 2, projectId.utf8String, -1, nil)
            }
        )
    }

    func update(user: User) throws {
        let updateUser = """
            UPDATE User
            SET revoked = ?, pinLength = ? , mpinId = ?, token = ?, dtas = ?, publicKey = ?
            WHERE userId = ? AND projectId = ?;
        """

        try sqliteHelper.update(
            statement: updateUser,
            buildBindings: { updateStatement in
                let revoked = user.revoked as NSNumber
                sqlite3_bind_int(updateStatement, 1, revoked.int32Value)

                let pinLength = user.pinLength as NSNumber
                sqlite3_bind_int(updateStatement, 2, pinLength.int32Value)

                _ = user.mpinId.withUnsafeBytes {
                    sqlite3_bind_blob(updateStatement, 3, $0.baseAddress, Int32($0.count), SQLITE_TRANSIENT)
                }

                _ = user.token.withUnsafeBytes {
                    sqlite3_bind_blob(updateStatement, 4, $0.baseAddress, Int32($0.count), SQLITE_TRANSIENT)
                }

                let dtas = user.dtas as NSString
                sqlite3_bind_text(updateStatement, 5, dtas.utf8String, -1, nil)

                if let publicKey = user.publicKey {
                    _ = publicKey.withUnsafeBytes {
                        sqlite3_bind_blob(updateStatement, 6, $0.baseAddress, Int32($0.count), SQLITE_TRANSIENT)
                    }
                }

                let userId = user.userId as NSString
                sqlite3_bind_text(updateStatement, 7, userId.utf8String, -1, nil)

                let projectId = user.projectId as NSString
                sqlite3_bind_text(updateStatement, 8, projectId.utf8String, -1, nil)
            }
        )
    }

    func all() -> [User] {
        let selectAllUsers = """
            SELECT * FROM User
        """

        do {
            var users = [User]()
            try sqliteHelper.select(
                statement: selectAllUsers,
                bindingsBlock: nil,
                bindResultBlock: { statement in
                    let userId = String(cString: sqlite3_column_text(statement, 0))
                    let projectId = String(cString: sqlite3_column_text(statement, 1))

                    let isRevoked = Int(sqlite3_column_int(statement, 2))
                    let revoked = Bool(truncating: isRevoked as NSNumber)

                    let dtas = String(cString: sqlite3_column_text(statement, 3))

                    var mpinId = Data()
                    if let pointer = sqlite3_column_blob(statement, 4) {
                        let size = sqlite3_column_bytes(statement, 4)
                        let data = Data(bytes: pointer, count: Int(size))

                        mpinId = data
                    }

                    var token = Data()
                    if let pointer = sqlite3_column_blob(statement, 5) {
                        let size = sqlite3_column_bytes(statement, 5)
                        let data = Data(bytes: pointer, count: Int(size))

                        token = data
                    }

                    let pinLength = Int(sqlite3_column_int(statement, 6))

                    var publicKey: Data?
                    if let pointer = sqlite3_column_blob(statement, 7) {
                        let size = sqlite3_column_bytes(statement, 7)
                        let data = Data(bytes: pointer, count: Int(size))

                        publicKey = data
                    }

                    let iteratedUser = User(
                        userId: userId,
                        projectId: projectId,
                        revoked: revoked,
                        pinLength: pinLength,
                        mpinId: mpinId,
                        token: token,
                        dtas: dtas,
                        publicKey: publicKey
                    )
                    users.append(iteratedUser)
                }
            )
            return users
        } catch {
            return []
        }
    }

    func getUser(by userId: String, projectId: String) -> User? {
        let selectUserByUserIdAndProjectId = """
            SELECT * FROM User WHERE userId = ? AND projectId = ?
        """

        do {
            var user: User?
            try sqliteHelper.select(
                statement: selectUserByUserIdAndProjectId,
                bindingsBlock: { statement in
                    let userId = userId as NSString
                    sqlite3_bind_text(statement, 1, userId.utf8String, -1, nil)

                    let projectId = projectId as NSString
                    sqlite3_bind_text(statement, 2, projectId.utf8String, -1, nil)
                }, bindResultBlock: { statement in
                    let userId = String(cString: sqlite3_column_text(statement, 0))
                    let projectId = String(cString: sqlite3_column_text(statement, 1))

                    let isRevoked = Int(sqlite3_column_int(statement, 2))
                    let revoked = Bool(truncating: isRevoked as NSNumber)

                    let dtas = String(cString: sqlite3_column_text(statement, 3))

                    var mpinId = Data()
                    if let pointer = sqlite3_column_blob(statement, 4) {
                        let size = sqlite3_column_bytes(statement, 4)
                        let data = Data(bytes: pointer, count: Int(size))

                        mpinId = data
                    }

                    var token = Data()
                    if let pointer = sqlite3_column_blob(statement, 5) {
                        let size = sqlite3_column_bytes(statement, 5)
                        let data = Data(bytes: pointer, count: Int(size))

                        token = data
                    }

                    let pinLength = Int(sqlite3_column_int(statement, 6))

                    var publicKey: Data?
                    if let pointer = sqlite3_column_blob(statement, 7) {
                        let size = sqlite3_column_bytes(statement, 7)
                        let data = Data(bytes: pointer, count: Int(size))

                        publicKey = data
                    }
                    user = User(
                        userId: userId,
                        projectId: projectId,
                        revoked: revoked,
                        pinLength: pinLength,
                        mpinId: mpinId,
                        token: token,
                        dtas: dtas,
                        publicKey: publicKey
                    )
                }
            )
            return user
        } catch {
            return nil
        }
    }
}
