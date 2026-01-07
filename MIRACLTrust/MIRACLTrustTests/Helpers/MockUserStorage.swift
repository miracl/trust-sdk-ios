@testable import MIRACLTrust

enum MockUserStorageError: Error {
    case testError
}

class MockUserStorage: UserStorage, @unchecked Sendable {
    var authenticationUsersMockArray = [UserDTO]()
    var getUserThrowsError = false
    var getUsersThrowsError = false
    var deleteUserThrowsError = false

    func loadStorage() throws {}

    func add(user: UserDTO) throws {
        authenticationUsersMockArray.append(user)
    }

    func delete(user: UserDTO) throws {
        if deleteUserThrowsError {
            throw MockUserStorageError.testError
        }

        if let index = authenticationUsersMockArray.firstIndex(where: { currentUser in
            user.userId == currentUser.userId &&
                user.projectId == currentUser.projectId
        }) {
            authenticationUsersMockArray.remove(at: index)
        }
    }

    func update(user: UserDTO) throws {
        if let index = authenticationUsersMockArray.firstIndex(where: { currentUser in
            currentUser.userId == user.userId &&
                currentUser.projectId == user.projectId
        }) {
            authenticationUsersMockArray[index] = user
        }
    }

    func all() throws -> [UserDTO] {
        if getUsersThrowsError {
            throw MockUserStorageError.testError
        }

        return authenticationUsersMockArray
    }

    func getUser(by userId: String, projectId: String) throws -> UserDTO? {
        if getUserThrowsError {
            throw MockUserStorageError.testError
        }

        return authenticationUsersMockArray.filter { user in
            user.userId == userId && user.projectId == projectId
        }.first
    }
}
