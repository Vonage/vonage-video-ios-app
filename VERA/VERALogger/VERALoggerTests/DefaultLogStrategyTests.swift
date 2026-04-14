//
//  Created by Vonage on 8/4/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("DefaultLogStrategy Tests")
struct DefaultLogStrategyTests {

    @Test("Format event without error includes level, thread, tag, and message")
    func formatEventWithoutError() {
        let strategy = DefaultLogStrategy()
        let event = LogEvent(
            level: .info,
            tag: "TestTag",
            message: "hello",
            timestamp: Date(timeIntervalSince1970: 1_000_000_000),
            thread: "main"
        )

        let formatted = strategy.formatEvent(event)

        #expect(formatted.contains("[INFO]"))
        #expect(formatted.contains("[main]"))
        #expect(formatted.contains("TestTag: hello"))
        #expect(!formatted.contains("\n"))
    }

    @Test("Format event with error includes error description")
    func formatEventWithError() {
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

        #expect(formatted.contains("[ERROR]"))
        #expect(formatted.contains("Err: broke"))
        #expect(formatted.contains("fail"))
    }

    @Test(
        "Format event includes correct level label",
        arguments: LogLevel.allCases
    )
    func allLogLevelsFormat(level: LogLevel) {
        let strategy = DefaultLogStrategy()
        let event = LogEvent(
            level: level,
            tag: "T",
            message: "msg",
            timestamp: Date(timeIntervalSince1970: 0),
            thread: "t"
        )

        let formatted = strategy.formatEvent(event)

        #expect(formatted.contains("[\(level)]"), "Missing level \(level)")
    }
}
