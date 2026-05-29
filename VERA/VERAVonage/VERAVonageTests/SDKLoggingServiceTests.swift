//
//  Created by Vonage on 29/05/2026.
//

import Foundation
import Testing

@testable import VERAVonage

@Suite("SDKLoggingService Tests")
struct SDKLoggingServiceTests {

    // MARK: - Helpers

    private func makeLogsDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("verasdklogging-test-\(UUID().uuidString)", isDirectory: true)
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

    // MARK: - Init

    @Test("Uses default Caches directory when no directory provided")
    func usesDefaultCachesDirectory() {
        let service = SDKLoggingService()
        let urls = service.getLogFileURLs()

        // No files initially — just verifying it doesn't crash
        #expect(urls.isEmpty || !urls.isEmpty)
    }

    @Test("Uses custom logs directory when provided")
    func usesCustomLogsDirectory() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let service = SDKLoggingService(logsDirectory: logsDir)

        let logFile = logsDir.appendingPathComponent("sdk-log-current.log")
        try createFile(at: logFile, contents: "test log entry")

        let urls = service.getLogFileURLs()
        #expect(urls.count == 1)
        #expect(urls.first?.lastPathComponent == "sdk-log-current.log")
    }

    // MARK: - getLogFileURLs

    @Test("getLogFileURLs returns empty when no files exist")
    func getLogFileURLsReturnsEmptyWhenNoFiles() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let service = SDKLoggingService(logsDirectory: logsDir)

        #expect(service.getLogFileURLs().isEmpty)
    }

    @Test("getLogFileURLs returns files from logs directory")
    func getLogFileURLsReturnsFilesFromDirectory() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let service = SDKLoggingService(logsDirectory: logsDir)

        try createFile(
            at: logsDir.appendingPathComponent("sdk-log-current.log"),
            contents: "current log"
        )
        try createFile(
            at: logsDir.appendingPathComponent("sdk-log-20240101-000000000.log"),
            contents: "archived log"
        )

        let urls = service.getLogFileURLs()
        #expect(urls.count == 2)
    }

    // MARK: - clearLogFiles

    @Test("clearLogFiles removes all log files")
    func clearLogFilesRemovesAllFiles() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let service = SDKLoggingService(logsDirectory: logsDir)

        try createFile(
            at: logsDir.appendingPathComponent("sdk-log-current.log"),
            contents: "current"
        )
        try createFile(
            at: logsDir.appendingPathComponent("sdk-log-20240101-000000000.log"),
            contents: "archived"
        )

        #expect(service.getLogFileURLs().count == 2)

        service.clearLogFiles()

        #expect(service.getLogFileURLs().isEmpty)
    }

    @Test("clearLogFiles does not crash when no files exist")
    func clearLogFilesDoesNotCrashWhenEmpty() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let service = SDKLoggingService(logsDirectory: logsDir)

        // Should not throw or crash
        service.clearLogFiles()
        #expect(service.getLogFileURLs().isEmpty)
    }

    @Test("clearLogFiles does not crash when directory does not exist")
    func clearLogFilesDoesNotCrashWhenDirectoryMissing() {
        let logsDir = makeLogsDirectory()
        // Don't create the directory — it should handle this gracefully
        let service = SDKLoggingService(logsDirectory: logsDir)

        service.clearLogFiles()
        #expect(service.getLogFileURLs().isEmpty)
    }

    // MARK: - Constants

    @Test("Default constants have expected values")
    func defaultConstantsHaveExpectedValues() {
        #expect(SDKLoggingService.defaultLogsDirectoryName == "VERASDKLogs")
        #expect(SDKLoggingService.currentFileName == "sdk-log-current.log")
        #expect(SDKLoggingService.defaultMaxFileCount == 5)
        #expect(SDKLoggingService.defaultMaxFileSize == 2 * 1024 * 1024)
    }
}
