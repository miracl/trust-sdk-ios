@testable import MIRACLTrust

class MockUserStorage: UserStorage, @unchecked Sendable {
    var authenticationUsersMockArray = [UserDTO]()
    var deletionResult = true

    func loadStorage() throws {}

    func add(user: UserDTO) throws {
        authenticationUsersMockArray.append(user)
    }

    func delete(user: UserDTO) throws {
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

    func all() -> [UserDTO] {
        authenticationUsersMockArray
    }

    func getUser(by userId: String, projectId: String) -> UserDTO? {
        authenticationUsersMockArray.filter { user in
            user.userId == userId && user.projectId == projectId
        }.first
    }
}
