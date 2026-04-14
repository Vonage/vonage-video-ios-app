//
//  Created by Vonage on 8/4/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("FileLogStrategy Tests")
struct FileLogStrategyTests {

    // MARK: - Test Helpers

    private func makeLogFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("veralogger-test-\(UUID().uuidString).log")
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Formatting

    @Test("Format event without error includes level, thread, tag, and message")
    func formatEventWithoutError() {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL)
        let event = LogEvent(
            level: .debug,
            tag: "MyTag",
            message: "hello world",
            timestamp: Date(timeIntervalSince1970: 1_000_000_000),
            thread: "test-thread"
        )

        let line = strategy.formatEvent(event)

        #expect(line.contains("[DEBUG]"))
        #expect(line.contains("[test-thread]"))
        #expect(line.contains("MyTag"))
        #expect(line.contains("hello world"))
        #expect(!line.contains("\n"))
    }

    @Test("Format event with error includes error description")
    func formatEventWithError() {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL)
        let error = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "boom"])
        let event = LogEvent(
            level: .error,
            tag: "Err",
            message: "failed",
            error: error,
            timestamp: Date(timeIntervalSince1970: 1_000_000_000),
            thread: "err-thread"
        )

        let line = strategy.formatEvent(event)

        #expect(line.contains("[ERROR]"))
        #expect(line.contains("[err-thread]"))
        #expect(line.contains("Err: failed"))
        #expect(line.contains("boom"))
    }

    // MARK: - File Writing

    @Test("Log writes to file")
    func logWritesToFile() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL)
        let event = LogEvent(level: .info, tag: "Tag", message: "test message")

        strategy.log(event)

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        #expect(content.contains("[INFO]"))
        #expect(content.contains("Tag: test message"))
    }

    @Test("Multiple events are appended on separate lines")
    func multipleEventsAppendedOnSeparateLines() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL)

        strategy.log(LogEvent(level: .debug, tag: "T", message: "first"))
        strategy.log(LogEvent(level: .info, tag: "T", message: "second"))
        strategy.log(LogEvent(level: .warn, tag: "T", message: "third"))

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }

        #expect(lines.count == 3)
        #expect(lines[0].contains("first"))
        #expect(lines[1].contains("second"))
        #expect(lines[2].contains("third"))
    }

    // MARK: - File Creation

    @Test("Creates file if it does not exist")
    func createsFileIfNotExists() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }

        #expect(!FileManager.default.fileExists(atPath: logFileURL.path))

        let strategy = FileLogStrategy(fileURL: logFileURL)
        strategy.log(LogEvent(level: .info, tag: "Tag", message: "create me"))

        #expect(FileManager.default.fileExists(atPath: logFileURL.path))
        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        #expect(content.contains("create me"))
    }

    // MARK: - Rotation

    @Test("Rotates file when max size is exceeded")
    func rotatesFileWhenMaxSizeExceeded() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let smallMax: UInt64 = 50
        let strategy = FileLogStrategy(fileURL: logFileURL, maxFileSize: smallMax)

        let bigContent = String(repeating: "x", count: 100)
        try bigContent.write(to: logFileURL, atomically: true, encoding: .utf8)

        strategy.log(LogEvent(level: .debug, tag: "T", message: "after rotation"))

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        #expect(content.contains("after rotation"))
        #expect(!content.contains(String(repeating: "x", count: 50)))
    }

    @Test("Does not rotate when file is under max size")
    func doesNotRotateWhenUnderMaxSize() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL, maxFileSize: 10_000)

        try "existing content\n".write(to: logFileURL, atomically: true, encoding: .utf8)

        strategy.log(LogEvent(level: .info, tag: "T", message: "new entry"))

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        #expect(content.contains("existing content"))
        #expect(content.contains("new entry"))
    }

    // MARK: - Constants

    @Test("Default constants have expected values")
    func defaultConstants() {
        #expect(FileLogStrategy.defaultMaxFileSize == 5 * 1024 * 1024)
        #expect(FileLogStrategy.defaultDateFormat == "yyyy-MM-dd HH:mm:ss.SSS")
    }
}
