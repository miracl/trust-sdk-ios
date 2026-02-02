/// An enumeration that describes HTTP request creation issues.
public enum APIRequestError: Error, Equatable, DefaultLocalizedError {
    /// Request failed.
    case fail(String)
}
