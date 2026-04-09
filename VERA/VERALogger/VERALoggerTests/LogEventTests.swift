//
//  Created by Vonage.
//

@testable import VERALogger
import XCTest

final class LogEventTests: XCTestCase {

    func testDefaultTimestampAndThread() {
        let before = Date()
        let event = LogEvent(level: .debug, tag: "T", message: "msg")
        let after = Date()

        XCTAssertGreaterThanOrEqual(event.timestamp, before)
        XCTAssertLessThanOrEqual(event.timestamp, after)
        XCTAssertFalse(event.thread.isEmpty)
    }

    func testCopyOverridesFields() {
        let event = LogEvent(level: .debug, tag: "Original", message: "msg")
        let copied = event.copy(tag: "Changed", message: "new msg")

        XCTAssertEqual(copied.tag, "Changed")
        XCTAssertEqual(copied.message, "new msg")
        XCTAssertEqual(copied.level, .debug) // unchanged
    }

    func testCopyPreservesUnchangedFields() {
        let error = NSError(domain: "test", code: 1)
        let event = LogEvent(
            level: .error,
            tag: "T",
            message: "msg",
            error: error,
            timestamp: Date(timeIntervalSince1970: 1000),
            thread: "mythread"
        )
        let copied = event.copy(level: .warn)

        XCTAssertEqual(copied.level, .warn)
        XCTAssertEqual(copied.tag, "T")
        XCTAssertEqual(copied.message, "msg")
        XCTAssertNotNil(copied.error)
        XCTAssertEqual(copied.timestamp, Date(timeIntervalSince1970: 1000))
        XCTAssertEqual(copied.thread, "mythread")
    }

    func testNilErrorDefault() {
        let event = LogEvent(level: .info, tag: "T", message: "msg")
        XCTAssertNil(event.error)
    }
}
