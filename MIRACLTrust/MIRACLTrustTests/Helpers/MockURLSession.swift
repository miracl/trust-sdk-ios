import Foundation

class URLSessionDataTaskMock: URLSessionDataTask, @unchecked Sendable {
    private let closure: () -> Void

    init(closure: @escaping () -> Void) {
        self.closure = closure
    }

    override func resume() {
        closure()
    }
}

class URLSessionMock: URLSession, @unchecked Sendable {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void

    var data: Data?
    var response: URLResponse?
    var error: Error?

    override func dataTask(
        with _: URLRequest,
        completionHandler: @escaping CompletionHandler
    ) -> URLSessionDataTask {
        let data = data
        let response = response
        let error = error

        let task = URLSessionDataTaskMock {
            completionHandler(data, response, error)
        }

        let taskCast = task as URLSessionDataTask

        return taskCast
    }
}
