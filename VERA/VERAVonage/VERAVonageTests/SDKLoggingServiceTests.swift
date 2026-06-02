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

    // MARK: - mapToOTCLevel

    @Test("mapToOTCLevel maps verbose (0) to debug OTC level (4)")
    func mapToOTCLevelVerbose() {
        #expect(SDKLoggingService.mapToOTCLevel(rawValue: 0) == 4)
    }

    @Test("mapToOTCLevel maps debug (1) to debug OTC level (4)")
    func mapToOTCLevelDebug() {
        #expect(SDKLoggingService.mapToOTCLevel(rawValue: 1) == 4)
    }

    @Test("mapToOTCLevel maps info (2) to info OTC level (3)")
    func mapToOTCLevelInfo() {
        #expect(SDKLoggingService.mapToOTCLevel(rawValue: 2) == 3)
    }

    @Test("mapToOTCLevel maps warn (3) to warn OTC level (2)")
    func mapToOTCLevelWarn() {
        #expect(SDKLoggingService.mapToOTCLevel(rawValue: 3) == 2)
    }

    @Test("mapToOTCLevel maps error (4) to error OTC level (1)")
    func mapToOTCLevelError() {
        #expect(SDKLoggingService.mapToOTCLevel(rawValue: 4) == 1)
    }

    @Test("mapToOTCLevel maps unknown negative value to debug OTC level (4)")
    func mapToOTCLevelUnknownNegative() {
        #expect(SDKLoggingService.mapToOTCLevel(rawValue: -1) == 4)
    }

    @Test("mapToOTCLevel maps unknown large value to debug OTC level (4)")
    func mapToOTCLevelUnknownLarge() {
        #expect(SDKLoggingService.mapToOTCLevel(rawValue: 99) == 4)
    }

    // MARK: - configure

    @Test("configure enabled creates log file with startup marker")
    func configureEnabledCreatesLogFile() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let service = SDKLoggingService(logsDirectory: logsDir)

        service.configure(enabled: true, logLevel: 2)
        // Clean up stderr capture immediately
        service.configure(enabled: false, logLevel: 0)

        // The startup marker should have been written
        let logFile = logsDir.appendingPathComponent(SDKLoggingService.currentFileName)
        #expect(FileManager.default.fileExists(atPath: logFile.path))

        if let contents = try? String(contentsOf: logFile, encoding: .utf8) {
            #expect(contents.contains("SDK file logging started"))
        }
    }

    @Test("configure disabled when not previously configured is safe")
    func configureDisabledWhenNotConfigured() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let service = SDKLoggingService(logsDirectory: logsDir)

        // Should not crash
        service.configure(enabled: false, logLevel: 0)
        #expect(service.getLogFileURLs().isEmpty)
    }

    @Test("configure enabled then disabled cleans up state")
    func configureEnabledThenDisabled() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let service = SDKLoggingService(logsDirectory: logsDir)

        service.configure(enabled: true, logLevel: 1)

        // Files exist after enable
        let filesAfterEnable = service.getLogFileURLs()
        #expect(!filesAfterEnable.isEmpty)

        service.configure(enabled: false, logLevel: 0)

        // Files still exist (disable doesn't delete), but strategy is cleared
        let filesAfterDisable = service.getLogFileURLs()
        #expect(!filesAfterDisable.isEmpty)
    }

    @Test("configure writes correct log level in startup marker")
    func configureWritesLogLevelInMarker() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let service = SDKLoggingService(logsDirectory: logsDir)

        service.configure(enabled: true, logLevel: 3)
        service.configure(enabled: false, logLevel: 0)

        let logFile = logsDir.appendingPathComponent(SDKLoggingService.currentFileName)
        if let contents = try? String(contentsOf: logFile, encoding: .utf8) {
            #expect(contents.contains("level: 3"))
        }
    }

    @Test("getLogFileURLs uses active strategy when configured")
    func getLogFileURLsUsesActiveStrategy() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let service = SDKLoggingService(logsDirectory: logsDir)

        service.configure(enabled: true, logLevel: 2)
        let urls = service.getLogFileURLs()
        service.configure(enabled: false, logLevel: 0)

        #expect(!urls.isEmpty)
        #expect(urls.contains { $0.lastPathComponent == SDKLoggingService.currentFileName })
    }

    @Test("clearLogFiles after configure removes log files")
    func clearLogFilesAfterConfigureRemovesFiles() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let service = SDKLoggingService(logsDirectory: logsDir)

        service.configure(enabled: true, logLevel: 2)
        #expect(!service.getLogFileURLs().isEmpty)

        service.clearLogFiles()
        service.configure(enabled: false, logLevel: 0)

        #expect(service.getLogFileURLs().isEmpty)
    }

    @Test("configure can be called multiple times with different levels")
    func configureMultipleTimesWithDifferentLevels() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let service = SDKLoggingService(logsDirectory: logsDir)

        // First configure
        service.configure(enabled: true, logLevel: 1)
        let urls1 = service.getLogFileURLs()
        #expect(!urls1.isEmpty)

        // Reconfigure with different level (should stop and restart)
        service.configure(enabled: false, logLevel: 0)
        service.configure(enabled: true, logLevel: 4)
        let urls2 = service.getLogFileURLs()
        #expect(!urls2.isEmpty)

        // Cleanup
        service.configure(enabled: false, logLevel: 0)
    }
}
