//
//  Created by Vonage on 8/4/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("LogFileInventory Tests")
struct LogFileInventoryTests {

    // MARK: - Helpers

    private func makeLogsDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("veralogger-inventory-\(UUID().uuidString)", isDirectory: true)
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

    private func makeInventory(
        fileURL: URL,
        logsDirectory: URL,
        archivePrefix: String = "sdk-log-"
    ) -> LogFileInventory {
        LogFileInventory(
            fileURL: fileURL,
            logsDirectory: logsDirectory,
            archivePrefix: archivePrefix,
            archiveSuffix: ".log"
        )
    }

    // MARK: - isManagedLogFile

    @Test("Recognises active log file as managed")
    func recognisesActiveLogFile() {
        let logsDir = makeLogsDirectory()
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let inventory = makeInventory(fileURL: fileURL, logsDirectory: logsDir)

        #expect(inventory.isManagedLogFile(fileURL))
    }

    @Test("Recognises valid archive file as managed")
    func recognisesValidArchiveFile() {
        let logsDir = makeLogsDirectory()
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let archiveURL = logsDir.appendingPathComponent("sdk-log-20240101-000000000.log")
        let inventory = makeInventory(fileURL: fileURL, logsDirectory: logsDir)

        #expect(inventory.isManagedLogFile(archiveURL))
    }

    @Test("Rejects file with wrong prefix")
    func rejectsWrongPrefix() {
        let logsDir = makeLogsDirectory()
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let wrongURL = logsDir.appendingPathComponent("other-20240101-000000000.log")
        let inventory = makeInventory(fileURL: fileURL, logsDirectory: logsDir)

        #expect(!inventory.isManagedLogFile(wrongURL))
    }

    @Test("Rejects file with wrong suffix")
    func rejectsWrongSuffix() {
        let logsDir = makeLogsDirectory()
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let wrongURL = logsDir.appendingPathComponent("sdk-log-20240101-000000000.txt")
        let inventory = makeInventory(fileURL: fileURL, logsDirectory: logsDir)

        #expect(!inventory.isManagedLogFile(wrongURL))
    }

    @Test("Rejects file with invalid timestamp format")
    func rejectsInvalidTimestamp() {
        let logsDir = makeLogsDirectory()
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let wrongURL = logsDir.appendingPathComponent("sdk-log-notadate.log")
        let inventory = makeInventory(fileURL: fileURL, logsDirectory: logsDir)

        #expect(!inventory.isManagedLogFile(wrongURL))
    }

    // MARK: - managedLogFileURLs

    @Test("Returns empty when directory does not exist")
    func returnsEmptyWhenNoDirectory() {
        let logsDir = makeLogsDirectory()
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let inventory = makeInventory(fileURL: fileURL, logsDirectory: logsDir)

        #expect(inventory.managedLogFileURLs(sortedNewestFirst: true).isEmpty)
    }

    @Test("Returns managed files sorted newest first")
    func returnsManagedFilesSortedNewestFirst() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let oldArchive = logsDir.appendingPathComponent("sdk-log-20240101-000000000.log")
        let newArchive = logsDir.appendingPathComponent("sdk-log-20240101-000001000.log")

        try createFile(at: oldArchive, contents: "old", modificationDate: Date(timeIntervalSince1970: 1))
        try createFile(at: newArchive, contents: "new", modificationDate: Date(timeIntervalSince1970: 2))
        try createFile(at: fileURL, contents: "current", modificationDate: Date(timeIntervalSince1970: 3))

        let inventory = makeInventory(fileURL: fileURL, logsDirectory: logsDir)
        let urls = inventory.managedLogFileURLs(sortedNewestFirst: true)

        #expect(urls.count == 3)
        #expect(urls[0].lastPathComponent == fileURL.lastPathComponent)
        #expect(urls[2].lastPathComponent == oldArchive.lastPathComponent)
    }

    @Test("Returns managed files sorted oldest first")
    func returnsManagedFilesSortedOldestFirst() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let oldArchive = logsDir.appendingPathComponent("sdk-log-20240101-000000000.log")
        let newArchive = logsDir.appendingPathComponent("sdk-log-20240101-000001000.log")

        try createFile(at: oldArchive, contents: "old", modificationDate: Date(timeIntervalSince1970: 1))
        try createFile(at: newArchive, contents: "new", modificationDate: Date(timeIntervalSince1970: 2))
        try createFile(at: fileURL, contents: "current", modificationDate: Date(timeIntervalSince1970: 3))

        let inventory = makeInventory(fileURL: fileURL, logsDirectory: logsDir)
        let urls = inventory.managedLogFileURLs(sortedNewestFirst: false)

        #expect(urls.count == 3)
        #expect(urls[0].lastPathComponent == oldArchive.lastPathComponent)
        #expect(urls[2].lastPathComponent == fileURL.lastPathComponent)
    }

    @Test("Excludes unrelated files from inventory")
    func excludesUnrelatedFiles() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let fileURL = logsDir.appendingPathComponent("sdk-log-current.log")
        let unrelated = logsDir.appendingPathComponent("other-file.txt")

        try createFile(at: fileURL, contents: "current")
        try createFile(at: unrelated, contents: "unrelated")

        let inventory = makeInventory(fileURL: fileURL, logsDirectory: logsDir)
        let urls = inventory.managedLogFileURLs(sortedNewestFirst: true)

        #expect(urls.count == 1)
        #expect(urls[0].lastPathComponent == fileURL.lastPathComponent)
    }
}
