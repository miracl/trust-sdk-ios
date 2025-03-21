import XCTest

public func assertError<T: Error & Equatable>(current: Error?, expected: T) {
    XCTAssertNotNil(current)
    XCTAssertTrue(current is T)
    XCTAssertEqual(current as? T, expected)
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
