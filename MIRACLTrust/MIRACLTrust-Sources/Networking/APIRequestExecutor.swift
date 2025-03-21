import Foundation

struct APIRequestExecutor: Sendable {
    var urlSession: URLSession
    let miraclLogger: MIRACLLogger

    init(urlSessionConfiguration: URLSessionConfiguration, miraclLogger: MIRACLLogger) {
        urlSession = URLSession(
            configuration: urlSessionConfiguration
        )
        self.miraclLogger = miraclLogger
    }

    func execute<T: Codable>(
        apiRequest: APIRequest<some Codable>,
        jsonDecoder: JSONDecoder = JSONDecoder(),
        completion: @escaping @Sendable (APICallResult, T?, Error?) -> Void
    ) {
        guard let urlRequest = apiRequest.urlRequest() else {
            completion(.failed, nil, APIRequestError.fail("Request cannot be created."))
            return
        }

        let task = urlSession.dataTask(
            with: urlRequest
        ) { data, response, error in

            if let error = error {
                completion(.failed, nil, error)
                return
            }

            guard let response = response as? HTTPURLResponse else {
                completion(.failed, nil, APIError.executionError("Response is not HTTPURLResponse", urlRequest.url))
                return
            }

            logRequestResponse(
                urlRequest: urlRequest,
                urlResponse: response,
                responseData: data
            )

            switch response.statusCode {
            case 200 ... 299:
                handleSuccess(
                    data: data,
                    jsonDecoder: jsonDecoder,
                    requestURL: urlRequest.url,
                    completion: completion
                )
                return
            case 400 ... 499:
                handleClientError(
                    data: data,
                    statusCode: response.statusCode,
                    requestURL: urlRequest.url,
                    completion: completion
                )
                return
            default:
                badStatusCode(
                    data: data,
                    statusCode: response.statusCode,
                    requestURL: urlRequest.url,
                    completion: completion
                )
                return
            }
        }
        task.resume()
    }

    func handleSuccess<T: Codable>(
        data: Data?,
        jsonDecoder: JSONDecoder,
        requestURL: URL?,
        completion: @escaping @Sendable (APICallResult, T?, Error?) -> Void
    ) {
        guard let data = data else {
            completion(.failed, nil, APIError.executionError("No data when request is succesful.", requestURL))
            return
        }

        do {
            if data.isEmpty {
                completion(.success, nil, nil)
            } else {
                let responseObject = try jsonDecoder.decode(
                    T.self,
                    from: data
                )
                completion(.success, responseObject, nil)
            }
        } catch {
            completion(
                .failed,
                nil,
                APIError.apiMalformedJSON(error, requestURL)
            )
        }
    }

    func handleClientError<T: Codable>(
        data: Data?,
        statusCode _: Int,
        requestURL: URL?,
        completion: @escaping @Sendable (APICallResult, T?, Error?) -> Void
    ) {
        guard let data = data else {
            completion(
                .failed,
                nil,
                APIError.apiClientError(
                    clientErrorData: nil,
                    requestId: "",
                    message: nil,
                    requestURL: requestURL
                )
            )
            return
        }

        let newErrorStructureParsingResult = parseNewErrorStructure(data: data)
        switch newErrorStructureParsingResult {
        case let .success(clientErrorData):
            completion(
                .failed,
                nil,
                APIError.apiClientError(
                    clientErrorData: clientErrorData,
                    requestId: clientErrorData.context?["requestID"] ?? "",
                    message: nil,
                    requestURL: requestURL
                )
            )

            return
        case .failure:
            let fallbackErrorStructureResult = parseFallbackErrorStructure(data: data)
            switch fallbackErrorStructureResult {
            case let .success(tuple):
                completion(
                    .failed,
                    nil,
                    APIError.apiClientError(
                        clientErrorData: tuple.clientErrorData,
                        requestId: tuple.requestId,
                        message: nil,
                        requestURL: requestURL
                    )
                )
                return
            case .failure:
                let message = getErrorDataAsString(data: data)
                completion(
                    .failed,
                    nil,
                    APIError.apiClientError(
                        clientErrorData: nil,
                        requestId: "",
                        message: message,
                        requestURL: requestURL
                    )
                )
            }
        }
    }

    func badStatusCode<T: Codable>(
        data: Data?,
        statusCode: Int,
        requestURL: URL?,
        completion: @escaping @Sendable (APICallResult, T?, Error?) -> Void
    ) {
        let messageError = getErrorDataAsString(data: data)
        completion(
            .failed,
            nil,
            APIError.apiServerError(
                statusCode: statusCode,
                message: messageError,
                requestURL: requestURL
            )
        )
    }

    private func getErrorDataAsString(data: Data?) -> String? {
        guard let data = data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private func logRequestResponse(
        urlRequest: URLRequest,
        urlResponse: URLResponse?,
        responseData: Data?
    ) {
        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            return
        }

        guard let httpMethod = urlRequest.httpMethod else {
            return
        }

        guard let url = urlRequest.url else {
            return
        }

        var loggingMessage = "\(httpMethod) \(url) \(httpURLResponse.statusCode)"

        if let responseData = responseData,
           let responseMessage = String(data: responseData, encoding: .utf8) {
            loggingMessage.append(" \(responseMessage)")
        }

        miraclLogger.debug(
            message: loggingMessage,
            category: .networking
        )
    }

    private func parseNewErrorStructure(data: Data) -> Result<ClientErrorData, Error> {
        do {
            let newErrorStructureErrorData = try JSONDecoder().decode(APIErrorResponse.self, from: data)

            let clientErrorData = ClientErrorData(
                code: newErrorStructureErrorData.error,
                info: newErrorStructureErrorData.info,
                context: newErrorStructureErrorData.context
            )

            return .success(clientErrorData)
        } catch {
            return .failure(error)
        }
    }

    private func parseFallbackErrorStructure(data: Data) -> Result<(clientErrorData: ClientErrorData, requestId: String), Error> {
        do {
            let newErrorStructureErrorData = try JSONDecoder().decode(FallbackRequestErrorResponse.self, from: data)

            let clientErrorData = ClientErrorData(
                code: newErrorStructureErrorData.error.code,
                info: newErrorStructureErrorData.error.info,
                context: newErrorStructureErrorData.error.context
            )

            return .success((clientErrorData, newErrorStructureErrorData.requestID))
        } catch {
            return .failure(error)
        }
    }
}
