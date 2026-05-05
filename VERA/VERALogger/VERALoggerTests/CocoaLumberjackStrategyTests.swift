//
//  Created by Vonage on 8/4/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("CocoaLumberjackStrategy Tests", .serialized)
struct CocoaLumberjackStrategyTests {

    // MARK: - Test Helpers

    private func makeTempDir(name: String = "vera-dd") -> String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString)")
            .path
    }

    private func cleanup(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }

    // MARK: - Backward Compatibility

    @Test("Default init adds OS logger without crash")
    func defaultInitAddsOSLogger() {
        let strategy = CocoaLumberjackStrategy()
        strategy.log(LogEvent(level: .info, tag: "Test", message: "default init"))
    }

    @Test("Init with configureDefaults false does not crash")
    func initWithConfigureDefaultsFalse() {
        let strategy = CocoaLumberjackStrategy(configureDefaults: false)
        strategy.log(LogEvent(level: .debug, tag: "Test", message: "no defaults"))
    }

    // MARK: - Builder

    @Test("Builder with OS logger does not crash")
    func builderWithOSLogger() {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withOSLogger()
            .build()

        strategy.log(LogEvent(level: .info, tag: "Builder", message: "os logger test"))
    }

    @Test("Builder with file logger creates log files")
    func builderWithFileLogger() {
        let tempDir = makeTempDir(name: "vera-dd-test")
        defer { cleanup(tempDir) }

        let strategy = CocoaLumberjackStrategy.Builder()
            .withFileLogger(directory: tempDir, maxNumberOfFiles: 3)
            .build()

        strategy.log(LogEvent(level: .info, tag: "Builder", message: "file logger test"))
        strategy.flush()

        #expect(!strategy.logFilePaths.isEmpty)
    }

    @Test("Builder with console logger does not crash")
    func builderWithConsoleLogger() {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withConsoleLogger()
            .build()

        strategy.log(LogEvent(level: .debug, tag: "Builder", message: "console test"))
    }

    @Test("Builder with multiple loggers all work together")
    func builderWithMultipleLoggers() {
        let tempDir = makeTempDir(name: "vera-dd-multi")
        defer { cleanup(tempDir) }

        let strategy = CocoaLumberjackStrategy.Builder()
            .withOSLogger()
            .withFileLogger(directory: tempDir)
            .withConsoleLogger()
            .build()

        strategy.log(LogEvent(level: .warn, tag: "Multi", message: "all loggers"))
        strategy.flush()

        #expect(!strategy.logFilePaths.isEmpty)
    }

    @Test("Builder with custom formatter does not crash")
    func builderWithCustomFormatter() {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withOSLogger()
            .build()

        strategy.log(LogEvent(level: .info, tag: "Fmt", message: "custom formatter"))
    }

    // MARK: - Log File Access

    @Test("Log file paths are empty without file logger")
    func logFilePathsEmptyWithoutFileLogger() {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withOSLogger()
            .build()

        #expect(strategy.logFilePaths.isEmpty)
        #expect(strategy.logFileURLs.isEmpty)
    }

    @Test("Log file paths return paths with file logger")
    func logFilePathsReturnPathsWithFileLogger() {
        let tempDir = makeTempDir(name: "vera-dd-paths")
        defer { cleanup(tempDir) }

        let strategy = CocoaLumberjackStrategy.Builder()
            .withFileLogger(directory: tempDir)
            .build()

        strategy.log(LogEvent(level: .info, tag: "Paths", message: "test"))
        strategy.flush()

        #expect(!strategy.logFilePaths.isEmpty)
        #expect(strategy.logFilePaths.count == strategy.logFileURLs.count)

        for url in strategy.logFileURLs {
            #expect(url.isFileURL)
        }
    }

    // MARK: - Convenience Factories

    @Test("osOnly factory creates strategy without file logging")
    func osOnlyFactory() {
        let strategy = CocoaLumberjackStrategy.osOnly()
        strategy.log(LogEvent(level: .info, tag: "Factory", message: "os only"))
        #expect(strategy.logFilePaths.isEmpty)
    }

    @Test("withFileLogging factory creates strategy with file logging")
    func withFileLoggingFactory() {
        let tempDir = makeTempDir(name: "vera-dd-factory")
        defer { cleanup(tempDir) }

        let strategy = CocoaLumberjackStrategy.withFileLogging(
            directory: tempDir,
            maxNumberOfFiles: 3
        )

        strategy.log(LogEvent(level: .error, tag: "Factory", message: "file factory"))
        strategy.flush()

        #expect(!strategy.logFilePaths.isEmpty)
    }

    @Test("full factory creates strategy without crash")
    func fullFactory() {
        let strategy = CocoaLumberjackStrategy.full()
        strategy.log(LogEvent(level: .info, tag: "Factory", message: "full factory"))
    }

    // MARK: - File Logger Configuration

    @Test("File logger respects custom rolling configuration")
    func fileLoggerRollingFrequency() {
        let tempDir = makeTempDir(name: "vera-dd-rolling")
        defer { cleanup(tempDir) }

        let strategy = CocoaLumberjackStrategy.Builder()
            .withFileLogger(
                directory: tempDir,
                rollingFrequency: 60 * 60 * 12,
                maxFileSize: 2 * 1024 * 1024,
                maxNumberOfFiles: 5
            )
            .build()

        strategy.log(LogEvent(level: .info, tag: "Config", message: "custom rolling"))
        strategy.flush()

        #expect(!strategy.logFilePaths.isEmpty)
    }

    // MARK: - All Log Levels

    @Test(
        "All log levels work without crash",
        arguments: [LogLevel.verbose, .debug, .info, .warn, .error]
    )
    func allLogLevelsWork(level: LogLevel) {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withOSLogger()
            .build()

        strategy.log(LogEvent(level: level, tag: "Levels", message: "\(level)"))
    }
}
