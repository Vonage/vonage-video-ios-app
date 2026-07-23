//
//  Created by Vonage on 8/4/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("LogEventFormatter Tests")
struct LogEventFormatterTests {

    // MARK: - Helpers

    private func makeFormatter(dateFormat: String = "yyyy-MM-dd HH:mm:ss.SSS") -> LogEventFormatter {
        let df = DateFormatter()
        df.dateFormat = dateFormat
        df.locale = Locale(identifier: "en_US_POSIX")
        return LogEventFormatter(dateFormatter: df)
    }

    private func makeEvent(
        level: LogLevel = .info,
        tag: String = "Tag",
        message: String = "message",
        error: Error? = nil
    ) -> LogEvent {
        LogEvent(
            level: level,
            tag: tag,
            message: message,
            error: error,
            timestamp: Date(timeIntervalSince1970: 1_000_000_000),
            thread: "test-thread"
        )
    }

    // MARK: - Format Tests

    @Test("Format event without error includes level, thread, tag, and message")
    func formatEventWithoutError() {
        let formatter = makeFormatter()
        let event = makeEvent(level: .debug, tag: "MyTag", message: "hello world")

        let line = formatter.format(event)

        #expect(line.contains("[DEBUG]"))
        #expect(line.contains("[test-thread]"))
        #expect(line.contains("MyTag"))
        #expect(line.contains("hello world"))
        #expect(!line.contains("\n"))
    }

    @Test("Format event with error includes error description")
    func formatEventWithError() {
        let formatter = makeFormatter()
        let error = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "boom"])
        let event = makeEvent(level: .error, tag: "Err", message: "failed", error: error)

        let line = formatter.format(event)

        #expect(line.contains("[ERROR]"))
        #expect(line.contains("Err: failed"))
        #expect(line.contains("boom"))
    }

    @Test("Custom date format is used in output")
    func customDateFormatUsed() {
        let formatter = makeFormatter(dateFormat: "HH:mm:ss")
        let event = makeEvent()

        let line = formatter.format(event)

        // Should not contain the date portion from the full format
        #expect(!line.contains("2001-09-09"))
    }

    @Test("Format preserves all log levels", arguments: LogLevel.allCases)
    func formatPreservesAllLevels(level: LogLevel) {
        let formatter = makeFormatter()
        let event = makeEvent(level: level)

        let line = formatter.format(event)

        #expect(line.contains("[\(level)]"))
    }
}
