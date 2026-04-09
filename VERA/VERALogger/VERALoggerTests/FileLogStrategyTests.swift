//
//  Created by Vonage.
//

@testable import VERALogger
import XCTest

final class FileLogStrategyTests: XCTestCase {

    private var logFileURL: URL!

    override func setUp() {
        super.setUp()
        let tempDir = FileManager.default.temporaryDirectory
        logFileURL = tempDir.appendingPathComponent("veralogger-test-\(UUID().uuidString).log")
        // Ensure clean state
        try? FileManager.default.removeItem(at: logFileURL)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: logFileURL)
        super.tearDown()
    }

    // MARK: - Formatting

    func testFormatEventWithoutError() {
        let strategy = FileLogStrategy(fileURL: logFileURL)
        let event = LogEvent(
            level: .debug,
            tag: "MyTag",
            message: "hello world",
            timestamp: Date(timeIntervalSince1970: 1_000_000_000),
            thread: "test-thread"
        )

        let line = strategy.formatEvent(event)

        XCTAssertTrue(line.contains("[DEBUG]"))
        XCTAssertTrue(line.contains("[test-thread]"))
        XCTAssertTrue(line.contains("MyTag"))
        XCTAssertTrue(line.contains("hello world"))
        XCTAssertFalse(line.contains("\n"))
    }

    func testFormatEventWithError() {
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

        XCTAssertTrue(line.contains("[ERROR]"))
        XCTAssertTrue(line.contains("[err-thread]"))
        XCTAssertTrue(line.contains("Err: failed"))
        XCTAssertTrue(line.contains("boom"))
    }

    // MARK: - File Writing

    func testLogWritesToFile() {
        let strategy = FileLogStrategy(fileURL: logFileURL)
        let event = LogEvent(level: .info, tag: "Tag", message: "test message")

        strategy.log(event)

        let content = try? String(contentsOf: logFileURL, encoding: .utf8)
        XCTAssertNotNil(content)
        XCTAssertTrue(content?.contains("[INFO]") == true)
        XCTAssertTrue(content?.contains("Tag: test message") == true)
    }

    func testMultipleEventsAppendedOnSeparateLines() {
        let strategy = FileLogStrategy(fileURL: logFileURL)

        strategy.log(LogEvent(level: .debug, tag: "T", message: "first"))
        strategy.log(LogEvent(level: .info, tag: "T", message: "second"))
        strategy.log(LogEvent(level: .warn, tag: "T", message: "third"))

        let content = try? String(contentsOf: logFileURL, encoding: .utf8)
        let lines = content?.components(separatedBy: "\n").filter { !$0.isEmpty } ?? []

        XCTAssertEqual(lines.count, 3)
        XCTAssertTrue(lines[0].contains("first"))
        XCTAssertTrue(lines[1].contains("second"))
        XCTAssertTrue(lines[2].contains("third"))
    }

    // MARK: - File Creation

    func testCreatesFileIfNotExists() {
        XCTAssertFalse(FileManager.default.fileExists(atPath: logFileURL.path))

        let strategy = FileLogStrategy(fileURL: logFileURL)
        strategy.log(LogEvent(level: .info, tag: "Tag", message: "create me"))

        XCTAssertTrue(FileManager.default.fileExists(atPath: logFileURL.path))
        let content = try? String(contentsOf: logFileURL, encoding: .utf8)
        XCTAssertTrue(content?.contains("create me") == true)
    }

    // MARK: - Rotation

    func testRotatesFileWhenMaxSizeExceeded() {
        let smallMax: UInt64 = 50
        let strategy = FileLogStrategy(fileURL: logFileURL, maxFileSize: smallMax)

        // Pre-fill the file past the limit
        let bigContent = String(repeating: "x", count: 100)
        try? bigContent.write(to: logFileURL, atomically: true, encoding: .utf8)

        strategy.log(LogEvent(level: .debug, tag: "T", message: "after rotation"))

        let content = try? String(contentsOf: logFileURL, encoding: .utf8)
        XCTAssertTrue(content?.contains("after rotation") == true)
        XCTAssertFalse(content?.contains(String(repeating: "x", count: 50)) == true)
    }

    func testDoesNotRotateWhenUnderMaxSize() {
        let strategy = FileLogStrategy(fileURL: logFileURL, maxFileSize: 10_000)

        try? "existing content\n".write(to: logFileURL, atomically: true, encoding: .utf8)

        strategy.log(LogEvent(level: .info, tag: "T", message: "new entry"))

        let content = try? String(contentsOf: logFileURL, encoding: .utf8)
        XCTAssertTrue(content?.contains("existing content") == true)
        XCTAssertTrue(content?.contains("new entry") == true)
    }

    // MARK: - Constants

    func testDefaultConstants() {
        XCTAssertEqual(FileLogStrategy.defaultMaxFileSize, 5 * 1024 * 1024)
        XCTAssertEqual(FileLogStrategy.defaultDateFormat, "yyyy-MM-dd HH:mm:ss.SSS")
    }
}
