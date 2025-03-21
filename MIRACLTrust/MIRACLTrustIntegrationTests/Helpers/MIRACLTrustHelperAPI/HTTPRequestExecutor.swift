import SwiftUI

public enum HelperAPIError: Error {
    case noData
    case internalError
    case parsingError
}

class HTTPRequestExecutor {
    func executeHTTPRequest<T: Codable & Sendable>(
        request: URLRequest,
        finish: @escaping @Sendable (Result<T?, HelperAPIError>) -> Void
    ) {
        let task = URLSession.shared.dataTask(with: request) { responseData, response, error in

            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    DispatchQueue.main.async {
                        finish(.failure(.noData))
                    }
                    return
                }
            }
            guard let data = responseData else {
                DispatchQueue.main.async {
                    finish(.failure(.noData))
                }
                return
            }

            if let response = response as? HTTPURLResponse,
               response.statusCode == 200, data.isEmpty {
                DispatchQueue.main.async {
                    finish(.success(nil))
                }
                return
            }

            if error != nil {
                DispatchQueue.main.async {
                    finish(.failure(.internalError))
                }

                return
            }

            let jsonDecoder = JSONDecoder()
            jsonDecoder.dateDecodingStrategy = .secondsSince1970

            do {
                let dict = try jsonDecoder.decode(T.self, from: data)

                DispatchQueue.main.async {
                    finish(.success(dict))
                }

            } catch {
                DispatchQueue.main.async {
                    finish(.failure(.parsingError))
                }
            }
        }
        task.resume()
    }
}
