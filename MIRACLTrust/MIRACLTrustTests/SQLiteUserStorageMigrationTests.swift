@testable import MIRACLTrust
import XCTest

class SQLiteUserStorageMigrationTests: XCTestCase {
    let sqliteHelper = SQLiteHelper()
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    let databaseName = "test-for-migration"
    let usersCount = 10

    var userIds = [String]()
    var projectIds = [String]()
    var dtas = [String]()
    var mpinIds = [Data]()
    var tokens = [Data]()
    var lengths = [Int]()

    override func setUp() {
        super.setUp()

        userIds = [String]()
        projectIds = [String]()
        dtas = [String]()
        mpinIds = [Data]()
        tokens = [Data]()
        lengths = [Int]()

        for _ in 0 ..< usersCount {
            userIds.append(UUID().uuidString)
            projectIds.append(UUID().uuidString)
            dtas.append(UUID().uuidString)
            mpinIds.append(Data(randomArray()))
            tokens.append(Data(randomArray()))
            lengths.append(Int.random(in: 1 ..< 6))
        }
    }

    func testMigrationFromV0toV3() throws {
        try createV0Storage()

        let v1ProjectId = NSUUID().uuidString

        let storage = SQLiteUserStorage(projectId: v1ProjectId, databaseName: databaseName)

        let configuration = try Configuration
            .Builder(
                projectId: v1ProjectId
            )
            .userStorage(userStorage: storage)
            .build()

        // SDK is configured, so the migration is finished.
        XCTAssertNoThrow(try MIRACLTrust.configure(with: configuration))
        XCTAssertEqual(usersCount, MIRACLTrust.getInstance().users.count)

        for (index, user) in MIRACLTrust.getInstance().users.enumerated() {
            XCTAssertEqual(user.userId, userIds[index])
            XCTAssertEqual(user.projectId, v1ProjectId)
            XCTAssertEqual(user.revoked, false)
            XCTAssertEqual(user.dtas, dtas[index])
            XCTAssertEqual(user.pinLength, lengths[index])
            if index % 2 == 0 {
                XCTAssertNotNil(user.publicKey)
            } else {
                XCTAssertNil(user.publicKey)
            }
        }
    }

    func testMigrationFromV1toV3() throws {
        try createV1Storage()

        let storage = SQLiteUserStorage(projectId: NSUUID().uuidString, databaseName: databaseName)

        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString
            )
            .userStorage(userStorage: storage)
            .build()

        // SDK is configured, so the migration is finished.
        XCTAssertNoThrow(try MIRACLTrust.configure(with: configuration))
        XCTAssertEqual(usersCount, MIRACLTrust.getInstance().users.count)

        for (index, user) in MIRACLTrust.getInstance().users.enumerated() {
            XCTAssertEqual(user.userId, userIds[index])
            XCTAssertEqual(user.projectId, projectIds[index])
            XCTAssertEqual(user.revoked, false)
            XCTAssertEqual(user.dtas, dtas[index])
            XCTAssertEqual(user.pinLength, lengths[index])

            if index % 2 == 0 {
                XCTAssertNotNil(user.publicKey)
            } else {
                XCTAssertNil(user.publicKey)
            }
        }
    }

    func testMigrationFromV2toV3() throws {
        try createV2Storage()

        let storage = SQLiteUserStorage(projectId: NSUUID().uuidString, databaseName: databaseName)

        let configuration = try Configuration
            .Builder(
                projectId: NSUUID().uuidString
            )
            .userStorage(userStorage: storage)
            .build()

        // SDK is configured, so the migration is finished.
        XCTAssertNoThrow(try MIRACLTrust.configure(with: configuration))
        XCTAssertEqual(usersCount, MIRACLTrust.getInstance().users.count)
    }

    // MARK: Test override.

    override func tearDown() {
        super.tearDown()
        do {
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let path = fileURL.appendingPathComponent("\(databaseName).sqlite").relativePath
            try FileManager.default.removeItem(atPath: path)
            XCTAssertFalse(FileManager.default.fileExists(atPath: path))
        } catch {
            XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
        }
    }

    // MARK: Private

    private func randomArray() -> [UInt8] {
        (0 ..< 20).map { _ in .random(in: 1 ... 100) }
    }

    private func createV2Storage() throws {
        try sqliteHelper.openDatabaseConnection(for: databaseName)
        try sqliteHelper.encryptDatabase()
        try sqliteHelper.setCurrentDatabaseVersion(databaseVersion: 2)

        let alterOldTablesStatement = """
           BEGIN TRANSACTION;
            CREATE TABLE IF NOT EXISTS User(
                userId TEXT NOT NULL CHECK (length(userId) > 0),
                projectId TEXT NOT NULL CHECK (length(projectId) > 0),
                authenticationIdentityId TEXT NOT NULL CHECK (length(authenticationIdentityId) > 0),
                signingIdentityId TEXT CHECK (length(signingIdentityId) > 0),
                revoked BOOLEAN NOT NULL,
                PRIMARY KEY(userId, projectId)
            );

            CREATE TABLE IF NOT EXISTS Identity(
                uuid TEXT PRIMARY KEY CHECK (length(uuid) > 0),
                dtas TEXT NOT NULL CHECK (length(dtas) > 0),
                mpinId BLOB NOT NULL CHECK (length(mpinId) > 0),
                token BLOB NOT NULL CHECK (length(token) > 0),
                pinLength INTEGER NOT NULL,
                publicKey BLOB
            );
           COMMIT;
        """
        _ = sqlite3_exec(
            sqliteHelper.database,
            alterOldTablesStatement, nil, nil, nil
        )

        let statement = """
            INSERT INTO Identity (uuid, dtas, mpinId, token, pinLength, publicKey)
            VALUES (?, ?, ?, ?, ?, ?)
        """

        _ = try (0 ..< usersCount).map { element in
            let authenticationIdentityId = UUID().uuidString
            try sqliteHelper.insert(statement: statement) { insertStatement in

                let uuid = authenticationIdentityId as NSString
                sqlite3_bind_text(insertStatement, 1, uuid.utf8String, -1, nil)

                let dtas = self.dtas[element] as NSString
                sqlite3_bind_text(insertStatement, 2, dtas.utf8String, -1, nil)

                let mpinId = self.mpinIds[element]
                _ = mpinId.withUnsafeBytes {
                    sqlite3_bind_blob(insertStatement, 3, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
                }

                let token = self.tokens[element]
                _ = token.withUnsafeBytes {
                    sqlite3_bind_blob(insertStatement, 4, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
                }

                let pinLength = NSNumber(value: self.lengths[element])
                sqlite3_bind_int(insertStatement, 5, pinLength.int32Value)

                if element % 2 == 0 {
                    let publicKey = Data(self.randomArray())
                    _ = publicKey.withUnsafeBytes {
                        sqlite3_bind_blob(insertStatement, 6, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
                    }
                } else {
                    sqlite3_bind_null(insertStatement, 6)
                }
            }
            let insertUser = """
                INSERT INTO
                User(userId, projectId, authenticationIdentityId, signingIdentityId, revoked)
                VALUES (?, ?, ?, ?, ?)
            """
            try sqliteHelper.insert(statement: insertUser) { insertStatement in
                let userId = self.userIds[element] as NSString
                sqlite3_bind_text(insertStatement, 1, userId.utf8String, -1, nil)

                let projectId = self.projectIds[element] as NSString
                sqlite3_bind_text(insertStatement, 2, projectId.utf8String, -1, nil)

                let auth4 = authenticationIdentityId as NSString
                sqlite3_bind_text(insertStatement, 3, auth4.utf8String, -1, nil)

                if element % 2 == 0 {
                    sqlite3_bind_text(insertStatement, 4, auth4.utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(insertStatement, 4)
                }

                let revoked = NSNumber(false)
                sqlite3_bind_int(insertStatement, 5, revoked.int32Value)
            }
        }
    }

    private func createV1Storage() throws {
        try sqliteHelper.openDatabaseConnection(for: databaseName)
        try sqliteHelper.encryptDatabase()
        try sqliteHelper.setCurrentDatabaseVersion(databaseVersion: 1)

        let alterOldTablesStatement = """
           BEGIN TRANSACTION;
            CREATE TABLE IF NOT EXISTS Identity(
                uuid TEXT PRIMARY KEY CHECK (length(uuid) > 0),
                dtas TEXT NOT NULL CHECK (length(dtas) > 0),
                mpinId BLOB NOT NULL CHECK (length(mpinId) > 0),
                token BLOB NOT NULL CHECK (length(token) > 0),
                pinLength INTEGER NOT NULL,
                revoked BOOLEAN,
                publicKey BLOB
            );

            CREATE TABLE IF NOT EXISTS User(
                userId TEXT NOT NULL CHECK (length(userId) > 0),
                projectId TEXT NOT NULL CHECK (length(projectId) > 0),
                authenticationIdentityId TEXT NOT NULL CHECK (length(authenticationIdentityId) > 0),
                signingIdentityId TEXT CHECK (length(signingIdentityId) > 0),
                PRIMARY KEY(userId, projectId)
            );
           COMMIT;
        """
        _ = sqlite3_exec(
            sqliteHelper.database,
            alterOldTablesStatement, nil, nil, nil
        )

        let statement = """
            INSERT INTO Identity (uuid, dtas, mpinId, token, pinLength, revoked, publicKey)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """

        _ = try (0 ..< usersCount).map { element in
            let authenticationIdentityId = UUID().uuidString
            try sqliteHelper.insert(statement: statement) { insertStatement in

                let uuid = authenticationIdentityId as NSString
                sqlite3_bind_text(insertStatement, 1, uuid.utf8String, -1, nil)

                let dtas = self.dtas[element] as NSString
                sqlite3_bind_text(insertStatement, 2, dtas.utf8String, -1, nil)

                let mpinId = self.mpinIds[element]
                _ = mpinId.withUnsafeBytes {
                    sqlite3_bind_blob(insertStatement, 3, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
                }

                let token = self.tokens[element]
                _ = token.withUnsafeBytes {
                    sqlite3_bind_blob(insertStatement, 4, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
                }

                let pinLength = NSNumber(value: self.lengths[element])
                sqlite3_bind_int(insertStatement, 5, pinLength.int32Value)

                let revoked = NSNumber(false)
                sqlite3_bind_int(insertStatement, 6, revoked.int32Value)

                if element % 2 == 0 {
                    let publicKey = Data(self.randomArray())
                    _ = publicKey.withUnsafeBytes {
                        sqlite3_bind_blob(insertStatement, 7, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
                    }
                } else {
                    sqlite3_bind_null(insertStatement, 7)
                }
            }
            let insertUser = """
                INSERT INTO
                User(userId, projectId, authenticationIdentityId, signingIdentityId)
                VALUES (?, ?, ?, ?)
            """
            try sqliteHelper.insert(statement: insertUser) { insertStatement in
                let userId = self.userIds[element] as NSString
                sqlite3_bind_text(insertStatement, 1, userId.utf8String, -1, nil)

                let projectId = self.projectIds[element] as NSString
                sqlite3_bind_text(insertStatement, 2, projectId.utf8String, -1, nil)

                let auth4 = authenticationIdentityId as NSString
                sqlite3_bind_text(insertStatement, 3, auth4.utf8String, -1, nil)

                if element % 2 == 0 {
                    sqlite3_bind_text(insertStatement, 4, auth4.utf8String, -1, nil)
                } else {
                    sqlite3_bind_null(insertStatement, 4)
                }
            }
        }
    }

    private func createV0Storage() throws {
        try sqliteHelper.openDatabaseConnection(for: "test-for-migration")
        try sqliteHelper.encryptDatabase()
        try sqliteHelper.setCurrentDatabaseVersion(databaseVersion: 0)

        let alterOldTablesStatement = """
            BEGIN TRANSACTION;

            CREATE TABLE IF NOT EXISTS Identity(
               Id INTEGER PRIMARY KEY AUTOINCREMENT,
               userId TEXT NOT NULL,
               pinLength INTEGER NOT NULL,
               dtas TEXT NOT NULL,
               mpinId BLOB NOT NULL,
               token BLOB NOT NULL,
               UNIQUE(mpinId,token)
            );

            CREATE TABLE IF NOT EXISTS SigningUser(
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                identity_id INTEGER,
                publicKey BLOB NOT NULL,
                FOREIGN KEY(identity_id) REFERENCES Identity(Id)
                ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS User(
              Id INTEGER PRIMARY KEY AUTOINCREMENT,
              identity_id INTEGER,
              FOREIGN KEY(identity_id) REFERENCES Identity(Id)
              ON DELETE CASCADE
           );

           COMMIT;
        """
        _ = sqlite3_exec(
            sqliteHelper.database,
            alterOldTablesStatement, nil, nil, nil
        )

        let statement = """
            INSERT INTO Identity (userId, pinLength, dtas, mpinId, token)
            VALUES (?, ?, ?, ?, ?)
        """

        _ = try (0 ..< usersCount).map { element in
            var idOfIdentity: Int64 = 0
            try sqliteHelper.insert(statement: statement) { insertStatement in
                let userId = self.userIds[element] as NSString
                sqlite3_bind_text(insertStatement, 1, userId.utf8String, -1, nil)

                let pinLength = NSNumber(value: self.lengths[element])
                sqlite3_bind_int(insertStatement, 2, pinLength.int32Value)

                let dtas = self.dtas[element] as NSString
                sqlite3_bind_text(insertStatement, 3, dtas.utf8String, -1, nil)

                let mpinId = self.mpinIds[element]
                _ = mpinId.withUnsafeBytes {
                    sqlite3_bind_blob(insertStatement, 4, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
                }

                let token = self.tokens[element]
                _ = token.withUnsafeBytes {
                    sqlite3_bind_blob(insertStatement, 5, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
                }
            }
            idOfIdentity = Int64(sqlite3_last_insert_rowid(sqliteHelper.database))
            let insertUser = """
                INSERT INTO User (identity_id) VALUES (?)
            """

            try sqliteHelper.insert(statement: insertUser, buildBindings: { insertStatement in
                sqlite3_bind_int64(insertStatement, 1, idOfIdentity)
            })

            if element % 2 == 0 {
                let insertSigningUser = """
                    INSERT INTO SigningUser (identity_id, publicKey) VALUES (?,?)
                """

                try sqliteHelper.insert(statement: insertSigningUser, buildBindings: { insertStatement in
                    sqlite3_bind_int64(insertStatement, 1, idOfIdentity)
                    let publicKey = Data(self.randomArray())
                    _ = publicKey.withUnsafeBytes {
                        sqlite3_bind_blob(insertStatement, 2, $0.baseAddress, Int32($0.count), self.SQLITE_TRANSIENT)
                    }
                })
            }
        }
    }
}
