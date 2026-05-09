import CryptoKit
import XCTest

public func assertError<T: Error & Equatable>(current: Error?, expected: T) {
    XCTAssertNotNil(current)
    XCTAssertTrue(current is T)
    XCTAssertEqual(current as? T, expected)
}

public func createMailpitUserId() -> String {
    let baseUserId = ProcessInfo.processInfo.environment["mailpitEmailAddress"]!
    return baseUserId.replacingOccurrences(of: "{tag}", with: UUID().uuidString.lowercased())
}

extension Date {
    static func dateWithAddedMinutes(minutes: Int) -> Date? {
        Calendar.current.date(
            byAdding: .minute,
            value: minutes, to:
            Date()
        )
    }
}

extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        Data(utf8).base64EncodedString()
    }
}

extension String {
    func toHexString() -> String {
        utf8.map { String(format: "%02x", $0) }.joined()
    }
}

extension Digest {
    var bytes: [UInt8] {
        Array(makeIterator())
    }

    var data: Data {
        Data(bytes)
    }
}
