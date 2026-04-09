//
//  Created by Vonage.
//

@testable import VERALogger
import XCTest

final class DefaultLogStrategyTests: XCTestCase {

    func testFormatEventWithoutError() {
        let strategy = DefaultLogStrategy()
        let event = LogEvent(
            level: .info,
            tag: "TestTag",
            message: "hello",
            timestamp: Date(timeIntervalSince1970: 1_000_000_000),
            thread: "main"
        )

        let formatted = strategy.formatEvent(event)

        XCTAssertTrue(formatted.contains("[INFO]"))
        XCTAssertTrue(formatted.contains("[main]"))
        XCTAssertTrue(formatted.contains("TestTag: hello"))
        XCTAssertFalse(formatted.contains("\n"))
    }

    func testFormatEventWithError() {
        let strategy = DefaultLogStrategy()
        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "fail"])
        let event = LogEvent(
            level: .error,
            tag: "Err",
            message: "broke",
            error: error,
            timestamp: Date(timeIntervalSince1970: 1_000_000_000),
            thread: "bg"
        )

        let formatted = strategy.formatEvent(event)

        XCTAssertTrue(formatted.contains("[ERROR]"))
        XCTAssertTrue(formatted.contains("Err: broke"))
        XCTAssertTrue(formatted.contains("fail"))
    }

    func testAllLogLevelsFormat() {
        let strategy = DefaultLogStrategy()

        for level in LogLevel.allCases {
            let event = LogEvent(
                level: level,
                tag: "T",
                message: "msg",
                timestamp: Date(timeIntervalSince1970: 0),
                thread: "t"
            )
            let formatted = strategy.formatEvent(event)
            XCTAssertTrue(formatted.contains("[\(level)]"), "Missing level \(level)")
        }
    }
}
