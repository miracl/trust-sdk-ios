import Foundation

/// A type representing storage, where already registered users will be kept between app launches.
/// By default, this SDK implements storage using SQLite. Also, keep in mind that this protocol
/// doesn't provide any data encryption, and therefore, developers have to implement it themselves.
/// - Tag: protocols-UserStorage
public protocol UserStorage: Sendable {
    /// Loads storage and its data into the memory.
    func loadStorage() throws

    /// Adds a new user to the storage.
    /// - Parameter user: a user that needs to be added to the storage.
    func add(user: User) throws

    /// Deletes the user from the storage.
    /// - Parameter user: a user that needs to be deleted to the storage.
    func delete(user: User) throws

    /// Updates the user in the storage
    /// - Parameter user: a user that needs to be updated to the storage.
    func update(user: User) throws

    /// Get all users written in the storage.
    func all() -> [User]

    /// Get User object by its user id and project id. If User isn't present in the storage this method returns nil.
    /// - Parameters:
    ///   - userId: a user id to be checked in the storage.
    ///   - projectId: a project id to be checked in the storage.
    func getUser(by userId: String, projectId: String) -> User?
}
