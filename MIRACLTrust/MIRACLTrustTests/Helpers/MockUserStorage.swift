@testable import MIRACLTrust

class MockUserStorage: UserStorage, @unchecked Sendable {
    var authenticationUsersMockArray = [User]()
    var deletionResult = true

    func loadStorage() throws {}

    func add(user: User) throws {
        authenticationUsersMockArray.append(user)
    }

    func delete(user: User) throws {
        if let index = authenticationUsersMockArray.firstIndex(of: user) {
            authenticationUsersMockArray.remove(at: index)
        }
    }

    func update(user: User) throws {
        if let index = authenticationUsersMockArray.firstIndex(where: { currentUser in
            currentUser.userId == user.userId
        }) {
            authenticationUsersMockArray[index] = user
        }
    }

    func all() -> [User] {
        authenticationUsersMockArray
    }

    func getUser(by userId: String, projectId: String) -> User? {
        authenticationUsersMockArray.filter { user in
            user.userId == userId && user.projectId == projectId
        }.first
    }
}
