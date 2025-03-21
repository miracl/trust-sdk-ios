import Foundation

#if SWIFT_PACKAGE
    import SQLChiper
#else
    import MIRACLTrust.SQLChiper
#endif

final class SQLiteHelper: @unchecked Sendable {
    var database: OpaquePointer?
    private let queue = DispatchQueue(label: "com.miracl.sqlite.queue")

    deinit {
        queue.sync {
            if database != nil {
                sqlite3_close(database)
                database = nil
            }
        }
    }

    func openDatabaseConnection(for dbName: String) throws {
        try queue.sync {
            let directoryURL = try getDocumentsDirectory()
            var dbFileURL = directoryURL
                .appendingPathComponent("\(dbName).sqlite")
            let dbFilePath = dbFileURL.relativePath

            let defaultFileManager = FileManager.default
            if defaultFileManager.fileExists(atPath: dbFilePath) {
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true

                do {
                    try dbFileURL.setResourceValues(resourceValues)
                } catch {
                    throw error
                }
            }

            if sqlite3_open(dbFilePath, &database) != SQLITE_OK {
                throw SQLiteDefaultStorageError.noConnection
            }
        }
    }

    func encryptDatabase() throws {
        try queue.sync {
            let encryptionHelper = SQLiteEncryptionHandler()

            var encryptionKey = encryptionHelper.loadEncryptionKey()

            if encryptionKey == nil {
                encryptionKey = encryptionHelper.createEncryptionKey()
            }

            if !encryptionHelper.updateEncryptionKeyAccessibilityIfNeeded() {
                throw SQLiteDefaultStorageError.encryptionKeyUpdateError
            }

            guard let encryptionKeyAsNSString = encryptionKey as NSString? else {
                throw SQLiteDefaultStorageError.encryptionError
            }

            let dbOperationResult = sqlite3_key(
                database,
                encryptionKeyAsNSString.utf8String,
                Int32(encryptionKeyAsNSString.length)
            )

            if dbOperationResult != SQLITE_OK {
                throw SQLiteDefaultStorageError.encryptionError
            }
        }
    }

    func createTable(with statement: String) throws {
        try queue.sync {
            var createTableStatement: OpaquePointer?
            defer {
                sqlite3_finalize(createTableStatement)
            }

            var prepareQueryResult = sqlite3_prepare_v2(
                database,
                statement,
                -1,
                &createTableStatement,
                nil
            )

            guard prepareQueryResult == SQLITE_OK else {
                throw SQLiteDefaultStorageError.prepareStatementError(message: getErrorMessage())
            }

            prepareQueryResult = sqlite3_step(createTableStatement)
            guard prepareQueryResult == SQLITE_DONE else {
                throw SQLiteDefaultStorageError.sqliteQueryError(message: getErrorMessage())
            }
        }
    }

    func insert(
        statement: String,
        buildBindings: ((OpaquePointer?) -> Void)?
    ) throws {
        try queue.sync {
            var insertStatement: OpaquePointer?

            defer {
                sqlite3_finalize(insertStatement)
            }

            if sqlite3_prepare_v2(
                database,
                statement,
                -1,
                &insertStatement,
                nil
            ) == SQLITE_OK {
                if let buildBindings = buildBindings {
                    buildBindings(insertStatement)
                }

                let dbOperationResult = sqlite3_step(insertStatement)
                if dbOperationResult != SQLITE_DONE {
                    throw SQLiteDefaultStorageError.sqliteQueryError(message: getErrorMessage())
                }
            } else {
                throw SQLiteDefaultStorageError.prepareStatementError(message: getErrorMessage())
            }
        }
    }

    func select(
        statement: String,
        bindingsBlock: ((OpaquePointer?) -> Void)?,
        bindResultBlock: (OpaquePointer?) throws -> Void
    ) throws {
        try queue.sync {
            var selectStatement: OpaquePointer?
            defer {
                sqlite3_finalize(selectStatement)
            }

            let dbOperationResult = sqlite3_prepare_v2(
                database,
                statement,
                -1,
                &selectStatement,
                nil
            )
            guard dbOperationResult == SQLITE_OK else {
                throw SQLiteDefaultStorageError.prepareStatementError(message: getErrorMessage())
            }

            if let bindingsBlock = bindingsBlock {
                bindingsBlock(selectStatement)
            }

            while sqlite3_step(selectStatement) == SQLITE_ROW {
                try bindResultBlock(selectStatement)
            }
        }
    }

    func delete(statement: String, buildBindings: (OpaquePointer?) -> Void) throws {
        try queue.sync {
            var deleteStatement: OpaquePointer?
            defer {
                sqlite3_finalize(deleteStatement)
            }

            var dbOperationResult = sqlite3_prepare_v2(
                database,
                statement,
                -1,
                &deleteStatement,
                nil
            )

            guard dbOperationResult == SQLITE_OK else {
                throw SQLiteDefaultStorageError.prepareStatementError(message: getErrorMessage())
            }

            buildBindings(deleteStatement)

            dbOperationResult = sqlite3_step(deleteStatement)
            if dbOperationResult != SQLITE_DONE {
                throw SQLiteDefaultStorageError.sqliteQueryError(message: getErrorMessage())
            }
        }
    }

    func update(
        statement: String,
        buildBindings: (OpaquePointer?) -> Void
    ) throws {
        try queue.sync {
            var updateStatement: OpaquePointer?
            defer {
                sqlite3_finalize(updateStatement)
            }

            var dbOperationResult = sqlite3_prepare_v2(
                database,
                statement,
                -1,
                &updateStatement,
                nil
            )

            guard dbOperationResult == SQLITE_OK else {
                throw SQLiteDefaultStorageError.prepareStatementError(message: getErrorMessage())
            }

            buildBindings(updateStatement)

            dbOperationResult = sqlite3_step(updateStatement)

            guard dbOperationResult == SQLITE_DONE else {
                throw SQLiteDefaultStorageError.sqliteQueryError(message: getErrorMessage())
            }
        }
    }

    func transaction(runStatementsBlock: () throws -> Void) throws {
        try queue.sync {
            sqlite3_exec(database, "BEGIN TRANSACTION;", nil, nil, nil)
            try runStatementsBlock()
            sqlite3_exec(database, "COMMIT;", nil, nil, nil)
        }
    }

    func getCurrentDatabaseVersion() throws -> Int {
        try queue.sync {
            var versionStatement: OpaquePointer?
            defer {
                sqlite3_finalize(versionStatement)
            }

            let dbOperationResult = sqlite3_prepare_v2(
                database,
                "PRAGMA user_version;",
                -1,
                &versionStatement,
                nil
            )

            guard dbOperationResult == SQLITE_OK else {
                throw SQLiteDefaultStorageError.prepareStatementError(message: getErrorMessage())
            }

            var currentDatabaseVersion = Int32()
            while sqlite3_step(versionStatement) == SQLITE_ROW {
                currentDatabaseVersion = sqlite3_column_int(versionStatement, 0)
            }

            return Int(currentDatabaseVersion)
        }
    }

    func setCurrentDatabaseVersion(databaseVersion: Int) throws {
        try queue.sync {
            let statement = """
                PRAGMA user_version = \(databaseVersion);
            """
            let result = sqlite3_exec(database, statement, nil, nil, nil)
            if result != SQLITE_OK {
                throw SQLiteDefaultStorageError.sqliteQueryError(message: getErrorMessage())
            }
        }
    }

    func isMigrationNeeded(currentDatabaseVersion: Int, requestedDatabaseVersion: Int) -> Bool {
        var isNeeded = false
        if currentDatabaseVersion < requestedDatabaseVersion {
            isNeeded.toggle()
        }

        return isNeeded
    }

    func getDocumentsDirectory() throws -> URL {
        guard let directoryURL = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else {
            throw SQLiteDefaultStorageError.noDir
        }
        return directoryURL
    }

    private func getErrorMessage() -> String? {
        if let errorPointer = sqlite3_errmsg(database) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        }
        return nil
    }
}
