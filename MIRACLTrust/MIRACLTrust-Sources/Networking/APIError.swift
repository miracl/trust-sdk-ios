import Foundation

// An enumeration that describes network issues.
public enum APIError: Error {
    /// The request response is a server error (5xx).
    case apiServerError(statusCode: Int, message: String?, requestURL: URL?)

    /// The request response is a client error (4xx).
    case apiClientError(clientErrorData: ClientErrorData?, requestId: String, message: String?, requestURL: URL?)

    /// JSON received as a response is invalid.
    case apiMalformedJSON(Error?, URL?)

    // Error while executing HTTP request.
    case executionError(String, URL?)
}

extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
    }
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        var description = ""
        switch self {
        case let .apiServerError(statusCode, message, requestURL):
            description = NSLocalizedString("\(APIError.apiServerError(statusCode: statusCode, message: message, requestURL: requestURL))", comment: "")
        case let .apiClientError(clientErrorData: clientErrorData, requestId: requestId, message: message, requestURL: requestURL):
            description = NSLocalizedString("\(APIError.apiClientError(clientErrorData: clientErrorData, requestId: requestId, message: message, requestURL: requestURL))", comment: "")
        case let .apiMalformedJSON(error, requestURL):
            description = NSLocalizedString("\(APIError.apiMalformedJSON(error, requestURL))", comment: "")
        case let .executionError(message, requestURL):
            description = NSLocalizedString("\(APIError.executionError(message, requestURL))", comment: "")
        }
        return description
    }
}

extension APIError: CustomNSError {
    public var errorCode: Int {
        switch self {
        case .apiServerError:
            return 1
        case .apiClientError:
            return 2
        case .apiMalformedJSON:
            return 3
        case .executionError:
            return 4
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .apiServerError(statusCode: statusCode, message: message, requestURL: requestURL):
            var badStatusCodeUserInfo = [String: Any]()
            badStatusCodeUserInfo["statusCode"] = statusCode

            if let message {
                badStatusCodeUserInfo["message"] = message
            }

            if let requestURL {
                badStatusCodeUserInfo["requestURL"] = requestURL.absoluteString
            }

            return badStatusCodeUserInfo
        case let .apiClientError(clientErrorData: clientErrorData, requestId: requestId, message: message, requestURL: requestURL):
            var clientErrorDataUserInfo = [String: Any]()
            if let clientErrorData {
                clientErrorDataUserInfo["code"] = clientErrorData.code
                clientErrorDataUserInfo["info"] = clientErrorData.info
                clientErrorDataUserInfo["requestId"] = requestId
                if let context = clientErrorData.context {
                    clientErrorDataUserInfo["context"] = context
                }

                if let message {
                    clientErrorDataUserInfo["message"] = message
                }

                if let requestURL {
                    clientErrorDataUserInfo["requestURL"] = requestURL.absoluteString
                }
            }
            return clientErrorDataUserInfo
        case let .apiMalformedJSON(error, requestURL):
            var malformedJSONErrorUserInfo = [String: Any]()

            if let error {
                malformedJSONErrorUserInfo["error"] = error
            }

            if let requestURL {
                malformedJSONErrorUserInfo["requestURL"] = requestURL.absoluteString
            }

            return malformedJSONErrorUserInfo
        default:
            return [String: Any]()
        }
    }
}
