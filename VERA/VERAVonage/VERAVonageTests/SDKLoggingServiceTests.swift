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

    @Test("Uses provided logs directory")
    func usesProvidedLogsDirectory() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

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
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

        #expect(service.getLogFileURLs().isEmpty)
    }

    @Test("getLogFileURLs returns files from logs directory")
    func getLogFileURLsReturnsFilesFromDirectory() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

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
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

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
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

        // Should not throw or crash
        service.clearLogFiles()
        #expect(service.getLogFileURLs().isEmpty)
    }

    @Test("clearLogFiles does not crash when directory does not exist")
    func clearLogFilesDoesNotCrashWhenDirectoryMissing() {
        let logsDir = makeLogsDirectory()
        // Don't create the directory — it should handle this gracefully
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

        service.clearLogFiles()
        #expect(service.getLogFileURLs().isEmpty)
    }

    // MARK: - Constants

    @Test("Default constants have expected values")
    func defaultConstantsHaveExpectedValues() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)

        #expect(factory.defaultLogsDirectoryName == "VERASDKLogs")
        #expect(factory.currentFileName == "sdk-log-current.log")
        #expect(factory.defaultMaxFileCount == 5)
        #expect(factory.defaultMaxFileSize == 2 * 1024 * 1024)
    }

    // MARK: - toOTCLevel

    @Test("toOTCLevel maps verbose (0) to debug OTC level (4)")
    func mapToOTCLevelVerbose() {
        #expect(0.toOTCLevel == 4)
    }

    @Test("toOTCLevel maps debug (1) to debug OTC level (4)")
    func mapToOTCLevelDebug() {
        #expect(1.toOTCLevel == 4)
    }

    @Test("toOTCLevel maps info (2) to info OTC level (3)")
    func mapToOTCLevelInfo() {
        #expect(2.toOTCLevel == 3)
    }

    @Test("toOTCLevel maps warn (3) to warn OTC level (2)")
    func mapToOTCLevelWarn() {
        #expect(3.toOTCLevel == 2)
    }

    @Test("toOTCLevel maps error (4) to error OTC level (1)")
    func mapToOTCLevelError() {
        #expect(4.toOTCLevel == 1)
    }

    @Test("toOTCLevel maps unknown negative value to debug OTC level (4)")
    func mapToOTCLevelUnknownNegative() {
        #expect((-1).toOTCLevel == 4)
    }

    @Test("toOTCLevel maps unknown large value to debug OTC level (4)")
    func mapToOTCLevelUnknownLarge() {
        #expect(99.toOTCLevel == 4)
    }

    // MARK: - configure

    @Test("configure enabled creates log file with startup marker")
    func configureEnabledCreatesLogFile() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

        service.configure(enabled: true, logLevel: 2)
        // Clean up stderr capture immediately
        service.configure(enabled: false, logLevel: 0)

        // The startup marker should have been written
        let logFile = logsDir.appendingPathComponent(factory.currentFileName)
        #expect(FileManager.default.fileExists(atPath: logFile.path))

        if let contents = try? String(contentsOf: logFile, encoding: .utf8) {
            #expect(contents.contains("SDK file logging started"))
        }
    }

    @Test("configure disabled when not previously configured is safe")
    func configureDisabledWhenNotConfigured() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

        // Should not crash
        service.configure(enabled: false, logLevel: 0)
        #expect(service.getLogFileURLs().isEmpty)
    }

    @Test("configure enabled then disabled cleans up state")
    func configureEnabledThenDisabled() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

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
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

        service.configure(enabled: true, logLevel: 3)
        service.configure(enabled: false, logLevel: 0)

        let logFile = logsDir.appendingPathComponent(factory.currentFileName)
        if let contents = try? String(contentsOf: logFile, encoding: .utf8) {
            #expect(contents.contains("level: 3"))
        }
    }

    @Test("getLogFileURLs uses active strategy when configured")
    func getLogFileURLsUsesActiveStrategy() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

        service.configure(enabled: true, logLevel: 2)
        let urls = service.getLogFileURLs()
        service.configure(enabled: false, logLevel: 0)

        #expect(!urls.isEmpty)
        #expect(urls.contains { $0.lastPathComponent == factory.currentFileName })
    }

    @Test("clearLogFiles after configure removes log files")
    func clearLogFilesAfterConfigureRemovesFiles() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

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
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

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

    // MARK: - makeFallbackStrategy

    @Test("getLogFileURLs uses fallback strategy when not configured")
    func getLogFileURLsUsesFallbackStrategy() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

        // Create a file in the logs directory without configuring the service
        try createFile(
            at: logsDir.appendingPathComponent("sdk-log-current.log"),
            contents: "fallback test"
        )

        // Should find the file through the fallback strategy
        let urls = service.getLogFileURLs()
        #expect(urls.count == 1)
    }

    @Test("clearLogFiles uses fallback strategy when not configured")
    func clearLogFilesUsesFallbackStrategy() throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

        try createFile(
            at: logsDir.appendingPathComponent("sdk-log-current.log"),
            contents: "will be deleted"
        )
        #expect(!service.getLogFileURLs().isEmpty)

        service.clearLogFiles()
        #expect(service.getLogFileURLs().isEmpty)
    }

    @Test("clearLogFiles with active strategy clears strategy files")
    func clearLogFilesWithActiveStrategy() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

        service.configure(enabled: true, logLevel: 2)
        #expect(!service.getLogFileURLs().isEmpty)

        service.clearLogFiles()
        #expect(service.getLogFileURLs().isEmpty)

        service.configure(enabled: false, logLevel: 0)
    }

    // MARK: - Thread Safety

    @Test("Concurrent getLogFileURLs and clearLogFiles do not crash")
    func concurrentAccessDoesNotCrash() async throws {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

        try createFile(
            at: logsDir.appendingPathComponent("sdk-log-current.log"),
            contents: "concurrent test"
        )

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    _ = service.getLogFileURLs()
                }
                group.addTask {
                    service.clearLogFiles()
                }
            }
        }

        // No crash — test passes if we get here
        #expect(true)
    }

    @Test("configure with each log level writes startup marker")
    func configureWithEachLogLevelWritesMarker() {
        for level in 0...4 {
            let logsDir = makeLogsDirectory()
            defer { cleanup(logsDir) }
            let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
            let fileStrategy = factory.makeStrategy()
            let service = SDKLoggingService(fileStrategy: fileStrategy)

            service.configure(enabled: true, logLevel: level)
            service.configure(enabled: false, logLevel: 0)

            let logFile = logsDir.appendingPathComponent(factory.currentFileName)
            let exists = FileManager.default.fileExists(atPath: logFile.path)
            #expect(exists, "Log file should exist for level \(level)")
        }
    }

    @Test("getLogFileURLs returns empty after clearLogFiles with no configure")
    func getLogFileURLsEmptyAfterClearNoConfig() {
        let logsDir = makeLogsDirectory()
        defer { cleanup(logsDir) }
        let factory = SDKFileLogStrategyFactory(logsDirectory: logsDir)
        let fileStrategy = factory.makeStrategy()
        let service = SDKLoggingService(fileStrategy: fileStrategy)

        service.clearLogFiles()
        #expect(service.getLogFileURLs().isEmpty)
    }
}
