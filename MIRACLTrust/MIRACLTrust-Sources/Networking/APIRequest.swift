import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

class APIRequest<T: Codable> {
    var urlComponents: URLComponents
    var method: HTTPMethod
    var requestBody: T?
    var miraclLogger: MIRACLLogger

    init(
        url: URL?,
        path: String?,
        method: HTTPMethod = .get,
        queryParameters: [String: String]? = nil,
        requestBody: T?,
        miraclLogger: MIRACLLogger
    ) throws {
        guard let baseURL = url, let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw APIRequestError.fail("Cannot create URL")
        }

        urlComponents = components

        guard let scheme = urlComponents.scheme else {
            throw APIRequestError.fail("Invalid URL Scheme")
        }

        if scheme.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw APIRequestError.fail("Invalid URL Scheme")
        }

        guard let host = urlComponents.host else {
            throw APIRequestError.fail("Invalid URL Host")
        }

        if host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw APIRequestError.fail("Invalid URL Host")
        }

        if let path = path {
            if !urlComponents.path.isEmpty {
                urlComponents.path.append("\(path)")
            } else {
                if path.starts(with: "/") {
                    urlComponents.path = path
                } else {
                    urlComponents.path = "/\(path)"
                }
            }
        }

        self.method = method
        self.requestBody = requestBody

        if let queryParameters = queryParameters {
            var queryItems = [URLQueryItem]()
            for (key, value) in queryParameters {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
            urlComponents.queryItems = queryItems
        }
        self.miraclLogger = miraclLogger

        miraclLogger.debug(
            message: "\(self.method.rawValue) \(urlComponents.url!.absoluteString)",
            category: .networking
        )
    }

    func urlRequest() -> URLRequest? {
        guard let url = urlComponents.url else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if method == .post || method == .put || method == .delete {
            if let requestBody = requestBody {
                let encoder = JSONEncoder()
                if let jsonData = try? encoder.encode(requestBody) {
                    request.httpBody = jsonData
                }
            }
        }
        return request
    }
}
