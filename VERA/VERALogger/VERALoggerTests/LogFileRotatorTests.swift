//
//  Created by Vonage on 8/4/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("LogFileRotator Tests")
struct LogFileRotatorTests {

    // MARK: - Helpers

    private func makeLogsDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("veralogger-rotator-\(UUID().uuidString)", isDirectory: true)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func createFile(at url: URL, contents: String) throws {
        let directory = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    private func makeRotator(
        fileURL: URL,
        logsDirectory: URL,
        maxFileSize: UInt64 = 100,
        rotationPolicy: FileLogStrategy.RotationPolicy = .truncate
    ) -> LogFileRotator {
        let fndf = DateFormatter()
        fndf.dateFormat = FileLogStrategy.archiveDateFormat
        fndf.locale = Locale(identifier: "en_US_POSIX")

        let inventory = LogFileInventory(
            fileURL: fileURL,
            logsDirectory: logsDirectory,
            archivePrefix: "sdk-log-",
            archiveSuffix: ".log"
        )

        let archiveManager = LogFileArchiveManager(
            logsDirectory: logsDirectory,
            archivePrefix: "sdk-log-",
            archiveSuffix: ".log",
            fileNameDateFormatter: fndf,
            inventory: inventory
        )

        return LogFileRotator(
            fileURL: fileURL,
            maxFileSize: maxFileSize,
            rotationPolicy: rotationPolicy,
            archiveManager: archiveManager
        )
    }

    // MARK: - Truncate Policy

    @Test("Truncate mode clears file when size exceeded")
    func truncateClearsFileWhenSizeExceeded() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let rotator = makeRotator(fileURL: fileURL, logsDirectory: logsDir, maxFileSize: 50)

        try createFile(at: fileURL, contents: String(repeating: "x", count: 60))

        rotator.rotateIfNeeded(appendingByteCount: 10)

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(content.isEmpty)
    }

    @Test("Truncate mode does not clear when under max size")
    func truncateDoesNotClearWhenUnderMax() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let rotator = makeRotator(fileURL: fileURL, logsDirectory: logsDir, maxFileSize: 500)

        try createFile(at: fileURL, contents: "small content")

        rotator.rotateIfNeeded(appendingByteCount: 10)

        let content = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(content == "small content")
    }

    // MARK: - Rolling Policy

    @Test("Rolling mode archives file and creates new empty one")
    func rollingArchivesAndCreatesNew() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let rotator = makeRotator(
            fileURL: fileURL,
            logsDirectory: logsDir,
            maxFileSize: 50,
            rotationPolicy: .rolling(maxFileCount: 5)
        )

        try createFile(at: fileURL, contents: String(repeating: "x", count: 60))

        rotator.rotateIfNeeded(appendingByteCount: 10)

        // Active file should be empty
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(content.isEmpty)

        // An archive should exist
        let files = try FileManager.default.contentsOfDirectory(
            at: logsDir, includingPropertiesForKeys: nil)
        let archives = files.filter { $0.lastPathComponent != fileURL.lastPathComponent }
        #expect(archives.count == 1)
    }

    @Test("Does nothing when file does not exist")
    func doesNothingWhenFileDoesNotExist() {
        let logsDir = makeLogsDirectory()
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let rotator = makeRotator(fileURL: fileURL, logsDirectory: logsDir, maxFileSize: 50)

        // Should not throw or crash
        rotator.rotateIfNeeded(appendingByteCount: 100)
    }
}
