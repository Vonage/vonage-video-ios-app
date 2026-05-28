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

    private func makeLogsDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("veralogger-rolling-\(UUID().uuidString)", isDirectory: true)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func makeEvent(
        level: LogLevel = .info,
        tag: String = "Tag",
        message: String = "message"
    ) -> LogEvent {
        LogEvent(
            level: level,
            tag: tag,
            message: message,
            timestamp: Date(timeIntervalSince1970: 1_000_000_000),
            thread: "test-thread"
        )
    }

    private func createFile(at url: URL, contents: String, modificationDate: Date? = nil) throws {
        let directory = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try contents.write(to: url, atomically: true, encoding: .utf8)
        if let modificationDate {
            try FileManager.default.setAttributes(
                [.modificationDate: modificationDate],
                ofItemAtPath: url.path
            )
        }
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

        strategy.log(makeEvent(level: .info, message: "test message"))

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        #expect(content.contains("[INFO]"))
        #expect(content.contains("Tag: test message"))
    }

    @Test("Multiple events are appended on separate lines")
    func multipleEventsAppendedOnSeparateLines() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL)

        strategy.log(makeEvent(level: .debug, message: "first"))
        strategy.log(makeEvent(level: .info, message: "second"))
        strategy.log(makeEvent(level: .warn, message: "third"))

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
        strategy.log(makeEvent(message: "create me"))

        #expect(FileManager.default.fileExists(atPath: logFileURL.path))
        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        #expect(content.contains("create me"))
    }

    // MARK: - Truncate Rotation

    @Test("Truncate mode: rotates file when max size is exceeded")
    func truncateRotatesFileWhenMaxSizeExceeded() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL, maxFileSize: 50)

        let bigContent = String(repeating: "x", count: 100)
        try bigContent.write(to: logFileURL, atomically: true, encoding: .utf8)

        strategy.log(makeEvent(message: "after rotation"))

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        #expect(content.contains("after rotation"))
        #expect(!content.contains(String(repeating: "x", count: 50)))
    }

    @Test("Truncate mode: does not rotate when under max size")
    func truncateDoesNotRotateWhenUnderMaxSize() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL, maxFileSize: 10_000)

        try "existing content\n".write(to: logFileURL, atomically: true, encoding: .utf8)

        strategy.log(makeEvent(message: "new entry"))

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        #expect(content.contains("existing content"))
        #expect(content.contains("new entry"))
    }

    @Test("Truncate mode: rotates when append would exceed max size")
    func truncateRotatesWhenAppendWouldExceedMaxSize() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL, maxFileSize: 200)

        let existingContent = String(repeating: "x", count: 180)
        try existingContent.write(to: logFileURL, atomically: true, encoding: .utf8)

        strategy.log(makeEvent(message: "new entry"))

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        #expect(content.contains("new entry"))
        #expect(!content.contains(existingContent))
    }

    @Test("Truncate mode: allLogFileURLs returns at most one file")
    func truncateAllLogFileURLsReturnsAtMostOneFile() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL)

        #expect(strategy.allLogFileURLs().isEmpty)

        strategy.log(makeEvent(message: "create"))
        #expect(strategy.allLogFileURLs().count == 1)
    }

    @Test("Truncate mode: deleteAllLogFiles removes the file")
    func truncateDeleteAllLogFiles() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL)

        strategy.log(makeEvent(message: "to delete"))
        #expect(FileManager.default.fileExists(atPath: logFileURL.path))

        strategy.deleteAllLogFiles()
        #expect(!FileManager.default.fileExists(atPath: logFileURL.path))
    }

    // MARK: - Rolling Rotation

    @Test("Rolling mode: creates directory and file if they do not exist")
    func rollingCreatesDirectoryAndFile() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let logFileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let strategy = FileLogStrategy(
            fileURL: logFileURL,
            rotationPolicy: .rolling(maxFileCount: 5)
        )

        #expect(!FileManager.default.fileExists(atPath: logsDir.path))

        strategy.log(makeEvent(message: "create me"))

        #expect(FileManager.default.fileExists(atPath: logsDir.path))
        #expect(FileManager.default.fileExists(atPath: logFileURL.path))
    }

    @Test("Rolling mode: archives file when max size is exceeded")
    func rollingRotatesFileWhenMaxSizeExceeded() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let logFileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let strategy = FileLogStrategy(
            fileURL: logFileURL,
            maxFileSize: 100,
            rotationPolicy: .rolling(maxFileCount: 5)
        )
        let existingContent = String(repeating: "x", count: 90)

        try createFile(at: logFileURL, contents: existingContent)

        strategy.log(makeEvent(message: "after rotation"))

        let allFiles = strategy.allLogFileURLs()
        let currentContent = try String(contentsOf: logFileURL, encoding: .utf8)
        let archives = allFiles.filter { $0.lastPathComponent != logFileURL.lastPathComponent }

        #expect(allFiles.count == 2)
        #expect(archives.count == 1)
        #expect(currentContent.contains("after rotation"))
        #expect(!currentContent.contains(existingContent))

        let archiveContent = try String(contentsOf: archives[0], encoding: .utf8)
        #expect(archiveContent.contains(existingContent))
    }

    @Test("Rolling mode: oldest files are deleted when exceeding max file count")
    func rollingOldestFilesDeletedWhenExceedingMaxFileCount() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let logFileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let strategy = FileLogStrategy(
            fileURL: logFileURL,
            maxFileSize: 100,
            rotationPolicy: .rolling(maxFileCount: 3)
        )
        let oldestFile = logsDir.appendingPathComponent("sdk-log-20240101-000000.log")
        let middleFile = logsDir.appendingPathComponent("sdk-log-20240101-000001.log")
        let newestArchive = logsDir.appendingPathComponent("sdk-log-20240101-000002.log")

        try createFile(at: oldestFile, contents: "oldest", modificationDate: Date(timeIntervalSince1970: 1))
        try createFile(at: middleFile, contents: "middle", modificationDate: Date(timeIntervalSince1970: 2))
        try createFile(at: newestArchive, contents: "newest", modificationDate: Date(timeIntervalSince1970: 3))
        try createFile(
            at: logFileURL,
            contents: String(repeating: "x", count: 90),
            modificationDate: Date(timeIntervalSince1970: 4)
        )

        strategy.log(makeEvent(message: "trigger rotation"))

        let fileNames = Set(strategy.allLogFileURLs().map(\.lastPathComponent))

        #expect(fileNames.count == 3)
        #expect(!fileNames.contains(oldestFile.lastPathComponent))
        #expect(!fileNames.contains(middleFile.lastPathComponent))
        #expect(fileNames.contains(newestArchive.lastPathComponent))
        #expect(fileNames.contains(logFileURL.lastPathComponent))
    }

    @Test("Rolling mode: allLogFileURLs returns files sorted newest first")
    func rollingAllLogFileURLsReturnsNewestFirst() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let logFileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let strategy = FileLogStrategy(
            fileURL: logFileURL,
            rotationPolicy: .rolling(maxFileCount: 5)
        )
        let oldestFile = logsDir.appendingPathComponent("sdk-log-20240101-000000.log")
        let newerFile = logsDir.appendingPathComponent("sdk-log-20240101-000001.log")

        try createFile(at: oldestFile, contents: "oldest", modificationDate: Date(timeIntervalSince1970: 1))
        try createFile(at: newerFile, contents: "newer", modificationDate: Date(timeIntervalSince1970: 2))
        try createFile(at: logFileURL, contents: "current", modificationDate: Date(timeIntervalSince1970: 3))

        let fileNames = strategy.allLogFileURLs().map(\.lastPathComponent)

        #expect(fileNames == [
            logFileURL.lastPathComponent,
            newerFile.lastPathComponent,
            oldestFile.lastPathComponent,
        ])
    }

    @Test("Rolling mode: deleteAllLogFiles removes all files")
    func rollingDeleteAllLogFilesRemovesAllFiles() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let logFileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let strategy = FileLogStrategy(
            fileURL: logFileURL,
            rotationPolicy: .rolling(maxFileCount: 5)
        )
        let rotatedFile = logsDir.appendingPathComponent("sdk-log-20240101-000000.log")

        try createFile(at: logFileURL, contents: "current")
        try createFile(at: rotatedFile, contents: "rotated")

        strategy.deleteAllLogFiles()

        #expect(strategy.allLogFileURLs().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: logFileURL.path))
        #expect(!FileManager.default.fileExists(atPath: rotatedFile.path))
    }

    // MARK: - Raw Writing

    @Test("writeRaw writes text verbatim without formatting")
    func writeRawWritesVerbatim() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL)

        strategy.writeRaw("raw line 1\nraw line 2\n")

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        #expect(content == "raw line 1\nraw line 2\n")
    }

    // MARK: - Min Level Filtering

    @Test("Respects minLevel filtering")
    func respectsMinLevelFiltering() throws {
        let logFileURL = makeLogFileURL()
        defer { cleanup(logFileURL) }
        let strategy = FileLogStrategy(fileURL: logFileURL, minLevel: .warn)

        let skippedEvent = makeEvent(level: .info, message: "skip me")
        let loggedEvent = makeEvent(level: .error, message: "log me")

        #expect(!strategy.shouldLog(skippedEvent))
        #expect(strategy.shouldLog(loggedEvent))

        strategy.log(skippedEvent)
        strategy.log(loggedEvent)

        let content = try String(contentsOf: logFileURL, encoding: .utf8)
        #expect(!content.contains("skip me"))
        #expect(content.contains("log me"))
    }

    // MARK: - Constants

    @Test("Default constants have expected values")
    func defaultConstants() {
        #expect(FileLogStrategy.defaultMaxFileSize == 5 * 1024 * 1024)
        #expect(FileLogStrategy.defaultDateFormat == "yyyy-MM-dd HH:mm:ss.SSS")
        #expect(FileLogStrategy.defaultMinLevel == .verbose)
    }
}
