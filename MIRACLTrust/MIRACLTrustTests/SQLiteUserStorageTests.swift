@testable import MIRACLTrust
import XCTest

class SQLiteUserStorageTests: XCTestCase {
    let testDatabaseName = "miracl-test"
    var storage = SQLiteUserStorage(projectId: UUID().uuidString, databaseName: "miracl-test")

    var projectId = UUID().uuidString

    override func setUpWithError() throws {
        let configuration = try Configuration
            .Builder(
                projectId: projectId
            )
            .userStorage(userStorage: storage)
            .build()
        try MIRACLTrust.configure(with: configuration)
    }

    override func tearDown() {
        super.tearDown()

        do {
            let fileURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let path = fileURL.appendingPathComponent("\(testDatabaseName).sqlite").relativePath
            try FileManager.default.removeItem(atPath: path)
            XCTAssertFalse(FileManager.default.fileExists(atPath: path))
        } catch {
            XCTFail("Fail at \(#function) on row \(#line) and error \(error)")
        }
    }

    // MARK: Migrations test

    // MARK: `add` method test

    func testAddUser() throws {
        let user = createUser()
        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        let userFromDB = try XCTUnwrap(storage.getUser(by: user.userId, projectId: user.projectId))
        XCTAssertEqual(userFromDB.userId, user.userId)
        XCTAssertEqual(userFromDB.projectId, user.projectId)
        XCTAssertEqual(userFromDB.revoked, user.revoked)
        XCTAssertEqual(userFromDB.mpinId, user.mpinId)
        XCTAssertEqual(userFromDB.token, user.token)
        XCTAssertEqual(userFromDB.dtas, user.dtas)
        XCTAssertEqual(userFromDB.pinLength, user.pinLength)
        XCTAssertEqual(userFromDB.publicKey, user.publicKey)
    }

    func testAddUserWithEmptyUserId() throws {
        let user = createUser(userId: "")
        XCTAssertThrowsError(try storage.add(user: user)) { error in
            XCTAssertNotNil(error as? SQLiteDefaultStorageError)
            var isErrorStorage = false
            if case SQLiteDefaultStorageError.sqliteQueryError(message: _) = error {
                isErrorStorage = true
            }

            XCTAssertTrue(isErrorStorage)
        }
    }

    func testAddUserWithoutPublicKey() throws {
        let user = createUser(publicKey: nil)
        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        let userFromDB = try XCTUnwrap(storage.getUser(by: user.userId, projectId: user.projectId))
        XCTAssertEqual(userFromDB.userId, user.userId)
        XCTAssertEqual(userFromDB.projectId, user.projectId)
        XCTAssertEqual(userFromDB.revoked, user.revoked)
        XCTAssertEqual(userFromDB.mpinId, user.mpinId)
        XCTAssertEqual(userFromDB.token, user.token)
        XCTAssertEqual(userFromDB.dtas, user.dtas)
        XCTAssertEqual(userFromDB.pinLength, user.pinLength)
        XCTAssertNil(userFromDB.publicKey)
    }

    func testAddAnotherUser() throws {
        let user = createUser()

        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        XCTAssertThrowsError(try storage.add(user: user)) { error in
            XCTAssertNotNil(error as? SQLiteDefaultStorageError)
            var isErrorStorage = false
            if case SQLiteDefaultStorageError.sqliteQueryError(message: _) = error {
                isErrorStorage = true
            }

            XCTAssertTrue(isErrorStorage)
        }
    }

    func testAddAnotherUserForNewUserIdForSameProjectId() throws {
        var user = createUser()

        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        var userFromDB = try XCTUnwrap(storage.getUser(by: user.userId, projectId: user.projectId))
        XCTAssertEqual(userFromDB.userId, user.userId)
        XCTAssertEqual(userFromDB.projectId, user.projectId)
        XCTAssertEqual(userFromDB.revoked, user.revoked)
        XCTAssertEqual(userFromDB.mpinId, user.mpinId)
        XCTAssertEqual(userFromDB.token, user.token)
        XCTAssertEqual(userFromDB.dtas, user.dtas)
        XCTAssertEqual(userFromDB.pinLength, user.pinLength)
        XCTAssertEqual(userFromDB.publicKey, user.publicKey)

        let secondUserId = UUID().uuidString
        user = createUser(userId: secondUserId)

        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 2)

        userFromDB = try XCTUnwrap(storage.getUser(by: secondUserId, projectId: user.projectId))
        XCTAssertEqual(userFromDB.userId, user.userId)
        XCTAssertEqual(userFromDB.projectId, user.projectId)
        XCTAssertEqual(userFromDB.revoked, user.revoked)
        XCTAssertEqual(userFromDB.mpinId, user.mpinId)
        XCTAssertEqual(userFromDB.token, user.token)
        XCTAssertEqual(userFromDB.dtas, user.dtas)
        XCTAssertEqual(userFromDB.pinLength, user.pinLength)
        XCTAssertEqual(userFromDB.publicKey, user.publicKey)
    }

    // MARK: `delete` method test

    func testDeleteUser() throws {
        let unwrappedUser = createUser()

        try storage.add(user: unwrappedUser)
        XCTAssertEqual(storage.all().count, 1)

        try storage.delete(user: unwrappedUser)
        XCTAssertEqual(storage.all().count, 0)
    }

    func testDeleteUnexistingUser() throws {
        var user = createUser()
        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        user = createUser(userId: "alice@miracl.com")

        try storage.delete(user: user)
        XCTAssertEqual(storage.all().count, 1)
    }

    func testDeleteEmptyUserId() throws {
        var user = createUser()
        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        user = createUser(userId: "")

        try storage.delete(user: user)
        XCTAssertEqual(storage.all().count, 1)
    }

    func testDeleteProjectId() throws {
        var user = createUser()

        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        projectId = ""
        user = createUser()

        try storage.delete(user: user)
        XCTAssertEqual(storage.all().count, 1)
    }

    // MARK: `update` method test

    func testUpdateUser() throws {
        var user = createUser()
        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        let updatedMpinId = Data([10, 11, 12])
        let updatedToken = Data([10, 11, 12])
        let updateDtas = UUID().uuidString
        let updatePublicKey = Data([10, 11, 12])

        user = createUser(
            userId: user.userId,
            projectId: user.projectId,
            mpinId: updatedMpinId,
            token: updatedToken,
            dtas: updateDtas,
            publicKey: updatePublicKey
        )

        try storage.update(user: user)
        XCTAssertEqual(storage.all().count, 1)

        let userFromDB = try XCTUnwrap(
            storage.getUser(
                by: user.userId,
                projectId: user.projectId
            )
        )

        XCTAssertEqual(storage.all().count, 1)
        XCTAssertEqual(userFromDB.userId, user.userId)
        XCTAssertEqual(userFromDB.projectId, user.projectId)
        XCTAssertEqual(userFromDB.revoked, user.revoked)
        XCTAssertEqual(userFromDB.mpinId, updatedMpinId)
        XCTAssertEqual(userFromDB.token, updatedToken)
        XCTAssertEqual(userFromDB.dtas, updateDtas)
        XCTAssertEqual(userFromDB.pinLength, user.pinLength)
        XCTAssertEqual(userFromDB.publicKey, updatePublicKey)
    }

    func testUpdateUserEmptyMpinId() throws {
        var user = createUser()
        let initialMPinID = user.mpinId

        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        let updatedMpinId = Data()
        let updatedToken = Data([10, 11, 12])
        let updateDtas = UUID().uuidString
        let updatePublicKey = Data([10, 11, 12])

        user = createUser(
            userId: user.userId,
            projectId: user.projectId,
            mpinId: updatedMpinId,
            token: updatedToken,
            dtas: updateDtas,
            publicKey: updatePublicKey
        )

        XCTAssertThrowsError(try storage.update(user: user)) { error in
            XCTAssertEqual(storage.all().count, 1)
            XCTAssertNotNil(error as? SQLiteDefaultStorageError)
            var isErrorStorage = false
            if case SQLiteDefaultStorageError.sqliteQueryError(message: _) = error {
                isErrorStorage = true
            }

            XCTAssertTrue(isErrorStorage)

            do {
                let userFromDB = try XCTUnwrap(
                    storage.getUser(
                        by: user.userId,
                        projectId: user.projectId
                    )
                )

                XCTAssertEqual(userFromDB.mpinId, initialMPinID)
            } catch {
                XCTFail("Cannot get user from the storage")
            }
        }
    }

    func testUpdateUserEmptyToken() throws {
        var user = createUser()
        let initialToken = user.token
        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        let updatedMpinId = Data([10, 11, 12])
        let updatedToken = Data()
        let updateDtas = UUID().uuidString
        let updatePublicKey = Data([10, 11, 12])

        user = createUser(
            userId: user.userId,
            projectId: user.projectId,
            mpinId: updatedMpinId,
            token: updatedToken,
            dtas: updateDtas,
            publicKey: updatePublicKey
        )

        XCTAssertThrowsError(try storage.update(user: user)) { error in
            XCTAssertEqual(storage.all().count, 1)
            XCTAssertNotNil(error as? SQLiteDefaultStorageError)
            var isErrorStorage = false
            if case SQLiteDefaultStorageError.sqliteQueryError(message: _) = error {
                isErrorStorage = true
            }

            XCTAssertTrue(isErrorStorage)

            do {
                let userFromDB = try XCTUnwrap(
                    storage.getUser(
                        by: user.userId,
                        projectId: user.projectId
                    )
                )

                XCTAssertEqual(userFromDB.token, initialToken)
            } catch {
                XCTFail("Cannot get user from the storage")
            }
        }
    }

    func testUpdateUserEmptyDtas() throws {
        var user = createUser()
        let dtasInitial = user.dtas

        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        let updatedMpinId = Data([10, 11, 12])
        let updatedToken = Data([10, 11, 12])
        let updateDtas = ""
        let updatePublicKey = Data([10, 11, 12])

        user = createUser(
            userId: user.userId,
            projectId: user.projectId,
            mpinId: updatedMpinId,
            token: updatedToken,
            dtas: updateDtas,
            publicKey: updatePublicKey
        )

        XCTAssertThrowsError(try storage.update(user: user)) { error in
            XCTAssertEqual(storage.all().count, 1)
            XCTAssertNotNil(error as? SQLiteDefaultStorageError)
            var isErrorStorage = false
            if case SQLiteDefaultStorageError.sqliteQueryError(message: _) = error {
                isErrorStorage = true
            }

            XCTAssertTrue(isErrorStorage)

            do {
                let userFromDB = try XCTUnwrap(
                    storage.getUser(
                        by: user.userId,
                        projectId: user.projectId
                    )
                )

                XCTAssertEqual(userFromDB.dtas, dtasInitial)
            } catch {
                XCTFail("Cannot get user from the storage")
            }
        }
    }

    func testUpdateUserNegativePinLength() throws {
        var user = createUser()
        let pinLengthInitial = user.pinLength

        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        user = createUser(
            userId: user.userId,
            projectId: user.projectId,
            pinLength: -1
        )

        XCTAssertThrowsError(try storage.update(user: user)) { error in
            XCTAssertEqual(storage.all().count, 1)
            XCTAssertNotNil(error as? SQLiteDefaultStorageError)
            var isErrorStorage = false
            if case SQLiteDefaultStorageError.sqliteQueryError(message: _) = error {
                isErrorStorage = true
            }

            XCTAssertTrue(isErrorStorage)

            do {
                let userFromDB = try XCTUnwrap(
                    storage.getUser(
                        by: user.userId,
                        projectId: user.projectId
                    )
                )

                XCTAssertEqual(userFromDB.pinLength, pinLengthInitial)
            } catch {
                XCTFail("Cannot get user from the storage")
            }
        }
    }

    func testUpdateUserEmptyProjectId() throws {
        let user = createUser()

        try storage.add(user: user)
        XCTAssertEqual(storage.all().count, 1)

        projectId = ""
        let secondUser = createUser()
        try storage.update(user: secondUser)
    }

    // MARK: `all()` tests

    func testAll() throws {
        let user = createUser()
        let firstUserId = user.userId
        try storage.add(user: user)

        let secondUserId = UUID().uuidString
        let secondUser = createUser(userId: secondUserId)
        try storage.add(user: secondUser)

        XCTAssertEqual(storage.all().count, 2)
        let users = storage.all()

        let firstUserResult = try XCTUnwrap(users[0])
        XCTAssertEqual(firstUserResult.userId, firstUserId)
        XCTAssertEqual(firstUserResult.projectId, user.projectId)
        XCTAssertEqual(firstUserResult.revoked, user.revoked)
        XCTAssertEqual(firstUserResult.mpinId, user.mpinId)
        XCTAssertEqual(firstUserResult.token, user.token)
        XCTAssertEqual(firstUserResult.dtas, user.dtas)
        XCTAssertEqual(firstUserResult.pinLength, user.pinLength)
        XCTAssertEqual(firstUserResult.publicKey, user.publicKey)

        let secondUserResult = try XCTUnwrap(users[1])
        XCTAssertEqual(secondUserResult.userId, secondUserId)
        XCTAssertEqual(secondUserResult.projectId, secondUser.projectId)
        XCTAssertEqual(secondUserResult.revoked, secondUser.revoked)
        XCTAssertEqual(secondUserResult.mpinId, secondUser.mpinId)
        XCTAssertEqual(secondUserResult.token, secondUser.token)
        XCTAssertEqual(secondUserResult.dtas, secondUser.dtas)
        XCTAssertEqual(secondUserResult.pinLength, secondUser.pinLength)
        XCTAssertEqual(secondUserResult.publicKey, secondUser.publicKey)
    }

    func testAllForZeroUsers() throws {
        let users = storage.all()
        XCTAssertEqual(users.count, 0)
    }

    // MARK: `getUser`

    func testGetUserByProjectIdAndUserID() throws {
        let user = createUser()
        try storage.add(user: user)

        let fetchedUser = try XCTUnwrap(storage.getUser(by: user.userId, projectId: user.projectId))
        XCTAssertEqual(fetchedUser.userId, user.userId)
        XCTAssertEqual(fetchedUser.projectId, user.projectId)
        XCTAssertEqual(fetchedUser.revoked, user.revoked)
        XCTAssertEqual(fetchedUser.mpinId, user.mpinId)
        XCTAssertEqual(fetchedUser.token, user.token)
        XCTAssertEqual(fetchedUser.dtas, user.dtas)
        XCTAssertEqual(fetchedUser.pinLength, user.pinLength)
        XCTAssertEqual(fetchedUser.publicKey, user.publicKey)
    }

    func testGetUserByDifferentUserId() throws {
        let unwrappedUser = createUser()
        try storage.add(user: unwrappedUser)

        let fetchedUser = storage.getUser(by: UUID().uuidString, projectId: unwrappedUser.projectId)
        XCTAssertNil(fetchedUser)
    }

    func testGetUserByDifferentProjectId() throws {
        let unwrappedUser = createUser()
        try storage.add(user: unwrappedUser)

        let fetchedUser = storage.getUser(by: unwrappedUser.userId, projectId: UUID().uuidString)
        XCTAssertNil(fetchedUser)
    }

    // MARK: Private

    private func assertError<T: Error & Equatable>(current: Error?, expected: T) {
        XCTAssertNotNil(current)
        XCTAssertTrue(current is T)
        XCTAssertEqual(current as? T, expected)
    }

    private func createUser(
        userId: String = UUID().uuidString,
        projectId: String = UUID().uuidString,
        revoked: Bool = Bool.random(),
        pinLength: Int = 4,
        mpinId: Data = Data([1, 2, 3]),
        token: Data = Data([3, 4, 5]),
        dtas: String = UUID().uuidString,
        publicKey: Data? = Data([6, 7, 8])
    ) -> User {
        User(
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
}
