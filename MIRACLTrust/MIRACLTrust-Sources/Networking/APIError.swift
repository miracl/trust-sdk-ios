import Foundation

/// An enumeration that describes network issues.
public enum APIError: Error, DefaultLocalizedError {
    /// The request response is a server error (5xx).
    case apiServerError(statusCode: Int, message: String?, requestURL: URL?)

    /// The request response is a client error (4xx).
    case apiClientError(statusCode: Int, clientErrorData: ClientErrorData?, requestId: String, message: String?, requestURL: URL?)

    /// JSON received as a response is invalid.
    case apiMalformedJSON(Error?, URL?)

    /// Error while executing HTTP request.
    case executionError(String, URL?)
}

extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        String(reflecting: lhs) == String(reflecting: rhs)
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
        case let .apiClientError(statusCode: statusCode, clientErrorData: clientErrorData, requestId: requestId, message: message, requestURL: requestURL):
            var clientErrorDataUserInfo = [String: Any]()
            clientErrorDataUserInfo["statusCode"] = statusCode
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
