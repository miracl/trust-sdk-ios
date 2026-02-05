import Foundation

/// A type representing the storage where registered users will be kept between app launches.
/// By default, this SDK implements storage using SQLite. Note that this protocol
/// does not provide any data encryption; therefore, developers must implement it themselves.
/// - Tag: protocols-UserStorage
public protocol UserStorage: Sendable {
    /// Loads storage and its data into the memory.
    func loadStorage() throws

    /// Adds a new user to the storage.
    /// - Parameter user: a user that must be added to the storage.
    func add(user: UserDTO) throws

    /// Deletes the user from the storage.
    /// - Parameter user: a user that must be deleted from the storage.
    func delete(user: UserDTO) throws

    /// Updates the user in the storage
    /// - Parameter user: a user that must be updated in the storage.
    func update(user: UserDTO) throws

    /// Gets all users written in the storage.
    func all() throws -> [UserDTO]

    /// Retrieves the `User` object from the given User ID and Project ID. Returns `nil` if the user is not found in the storage.
    /// - Parameters:
    ///   - userId: a User ID to be checked in the storage.
    ///   - projectId: a Project ID to be checked in the storage.
    func getUser(by userId: String, projectId: String) throws -> UserDTO?
}
