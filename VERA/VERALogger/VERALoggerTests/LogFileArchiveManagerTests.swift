//
//  Created by Vonage on 8/4/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("LogFileArchiveManager Tests")
struct LogFileArchiveManagerTests {

    // MARK: - Helpers

    private func makeLogsDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("veralogger-archive-\(UUID().uuidString)", isDirectory: true)
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
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

    private func makeManager(
        logsDirectory: URL,
        fileURL: URL,
        archivePrefix: String = "sdk-log-"
    ) -> LogFileArchiveManager {
        let fndf = DateFormatter()
        fndf.dateFormat = FileLogStrategy.archiveDateFormat
        fndf.locale = Locale(identifier: "en_US_POSIX")

        let inventory = LogFileInventory(
            fileURL: fileURL,
            logsDirectory: logsDirectory,
            archivePrefix: archivePrefix,
            archiveSuffix: ".log"
        )

        return LogFileArchiveManager(
            logsDirectory: logsDirectory,
            archivePrefix: archivePrefix,
            archiveSuffix: ".log",
            fileNameDateFormatter: fndf,
            inventory: inventory
        )
    }

    // MARK: - archiveFileName

    @Test("Generates archive filename with prefix and timestamp")
    func generatesArchiveFilename() {
        let logsDir = makeLogsDirectory()
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let manager = makeManager(logsDirectory: logsDir, fileURL: fileURL)
        let date = Date(timeIntervalSince1970: 1_000_000_000)

        let fileName = manager.archiveFileName(for: date)

        #expect(fileName.hasPrefix("sdk-log-"))
        #expect(fileName.hasSuffix(".log"))
        #expect(fileName.count > "sdk-log-.log".count)
    }

    // MARK: - archiveFile

    @Test("Archives file by moving it to timestamped name")
    func archivesFileToTimestampedName() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let manager = makeManager(logsDirectory: logsDir, fileURL: fileURL)

        try createFile(at: fileURL, contents: "original content")

        try manager.archiveFile(at: fileURL)

        // Original file should be recreated empty
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        let currentContent = try String(contentsOf: fileURL, encoding: .utf8)
        #expect(currentContent.isEmpty)

        // An archive should exist
        let files = try FileManager.default.contentsOfDirectory(
            at: logsDir, includingPropertiesForKeys: nil)
        let archives = files.filter { $0.lastPathComponent != fileURL.lastPathComponent }
        #expect(archives.count == 1)

        let archiveContent = try String(contentsOf: archives[0], encoding: .utf8)
        #expect(archiveContent == "original content")
    }

    // MARK: - pruneArchivedFiles

    @Test("Prunes oldest files when exceeding max count")
    func prunesOldestFilesWhenExceedingMaxCount() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let manager = makeManager(logsDirectory: logsDir, fileURL: fileURL)

        let oldest = logsDir.appendingPathComponent("sdk-log-20240101-000000000.log")
        let middle = logsDir.appendingPathComponent("sdk-log-20240101-000001000.log")
        let newest = logsDir.appendingPathComponent("sdk-log-20240101-000002000.log")

        try createFile(at: oldest, contents: "oldest", modificationDate: Date(timeIntervalSince1970: 1))
        try createFile(at: middle, contents: "middle", modificationDate: Date(timeIntervalSince1970: 2))
        try createFile(at: newest, contents: "newest", modificationDate: Date(timeIntervalSince1970: 3))
        try createFile(at: fileURL, contents: "current", modificationDate: Date(timeIntervalSince1970: 4))

        manager.pruneArchivedFiles(maxFileCount: 3, activeFileURL: fileURL)

        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        #expect(FileManager.default.fileExists(atPath: newest.path))
        #expect(FileManager.default.fileExists(atPath: middle.path))
        #expect(!FileManager.default.fileExists(atPath: oldest.path))
    }

    @Test("Does not prune when under max count")
    func doesNotPruneWhenUnderMaxCount() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let manager = makeManager(logsDirectory: logsDir, fileURL: fileURL)

        let archive = logsDir.appendingPathComponent("sdk-log-20240101-000000000.log")
        try createFile(at: archive, contents: "archive")
        try createFile(at: fileURL, contents: "current")

        manager.pruneArchivedFiles(maxFileCount: 5, activeFileURL: fileURL)

        #expect(FileManager.default.fileExists(atPath: archive.path))
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test("Never deletes the active file during pruning")
    func neverDeletesActiveFileDuringPruning() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let manager = makeManager(logsDirectory: logsDir, fileURL: fileURL)

        try createFile(at: fileURL, contents: "current", modificationDate: Date(timeIntervalSince1970: 1))

        manager.pruneArchivedFiles(maxFileCount: 1, activeFileURL: fileURL)

        #expect(FileManager.default.fileExists(atPath: fileURL.path))
    }
}
