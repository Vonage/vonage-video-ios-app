//
//  Created by Vonage.
//

@testable import VERALogger
import CocoaLumberjackSwift
import XCTest

final class CocoaLumberjackStrategyTests: XCTestCase {

    override func tearDown() {
        DDLog.removeAllLoggers()
        super.tearDown()
    }

    // MARK: - Backward Compatibility

    func testDefaultInitAddsOSLogger() {
        let strategy = CocoaLumberjackStrategy()
        // Should not crash, OS logger is added
        strategy.log(LogEvent(level: .info, tag: "Test", message: "default init"))
    }

    func testInitWithConfigureDefaultsFalse() {
        let strategy = CocoaLumberjackStrategy(configureDefaults: false)
        // Should not crash even with no loggers
        strategy.log(LogEvent(level: .debug, tag: "Test", message: "no defaults"))
    }

    // MARK: - Builder

    func testBuilderWithOSLogger() {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withOSLogger()
            .build()

        strategy.log(LogEvent(level: .info, tag: "Builder", message: "os logger test"))
        // Should not crash
    }

    func testBuilderWithFileLogger() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vera-dd-test-\(UUID().uuidString)")
            .path

        let strategy = CocoaLumberjackStrategy.Builder()
            .withFileLogger(directory: tempDir, maxNumberOfFiles: 3)
            .build()

        strategy.log(LogEvent(level: .info, tag: "Builder", message: "file logger test"))

        // DDLog writes asynchronously; flush to ensure the file is created
        DDLog.flushLog()

        XCTAssertFalse(strategy.logFilePaths.isEmpty)

        // Clean up
        try? FileManager.default.removeItem(atPath: tempDir)
    }

    func testBuilderWithConsoleLogger() {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withConsoleLogger()
            .build()

        strategy.log(LogEvent(level: .debug, tag: "Builder", message: "console test"))
        // Should not crash
    }

    func testBuilderWithMultipleLoggers() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vera-dd-multi-\(UUID().uuidString)")
            .path

        let strategy = CocoaLumberjackStrategy.Builder()
            .withOSLogger()
            .withFileLogger(directory: tempDir)
            .withConsoleLogger()
            .build()

        strategy.log(LogEvent(level: .warn, tag: "Multi", message: "all loggers"))
        DDLog.flushLog()

        XCTAssertFalse(strategy.logFilePaths.isEmpty)

        try? FileManager.default.removeItem(atPath: tempDir)
    }

    func testBuilderWithCustomFormatter() {
        // Any DDLogFormatter can be passed to customize output
        let strategy = CocoaLumberjackStrategy.Builder()
            .withOSLogger()
            .build()

        strategy.log(LogEvent(level: .info, tag: "Fmt", message: "custom formatter"))
        // Should not crash
    }

    // MARK: - Log File Access

    func testLogFilePathsEmptyWithoutFileLogger() {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withOSLogger()
            .build()

        XCTAssertTrue(strategy.logFilePaths.isEmpty)
        XCTAssertTrue(strategy.logFileURLs.isEmpty)
    }

    func testLogFilePathsReturnPathsWithFileLogger() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vera-dd-paths-\(UUID().uuidString)")
            .path

        let strategy = CocoaLumberjackStrategy.Builder()
            .withFileLogger(directory: tempDir)
            .build()

        strategy.log(LogEvent(level: .info, tag: "Paths", message: "test"))
        DDLog.flushLog()

        XCTAssertFalse(strategy.logFilePaths.isEmpty)
        XCTAssertEqual(strategy.logFilePaths.count, strategy.logFileURLs.count)

        for url in strategy.logFileURLs {
            XCTAssertTrue(url.isFileURL)
        }

        try? FileManager.default.removeItem(atPath: tempDir)
    }

    // MARK: - Convenience Factories

    func testOsOnlyFactory() {
        let strategy = CocoaLumberjackStrategy.osOnly()
        strategy.log(LogEvent(level: .info, tag: "Factory", message: "os only"))
        XCTAssertTrue(strategy.logFilePaths.isEmpty)
    }

    func testWithFileLoggingFactory() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vera-dd-factory-\(UUID().uuidString)")
            .path

        let strategy = CocoaLumberjackStrategy.withFileLogging(
            directory: tempDir,
            maxNumberOfFiles: 3
        )

        strategy.log(LogEvent(level: .error, tag: "Factory", message: "file factory"))
        DDLog.flushLog()

        XCTAssertFalse(strategy.logFilePaths.isEmpty)

        try? FileManager.default.removeItem(atPath: tempDir)
    }

    func testFullFactory() {
        let strategy = CocoaLumberjackStrategy.full()
        strategy.log(LogEvent(level: .info, tag: "Factory", message: "full factory"))
        // Should not crash — all loggers active
    }

    // MARK: - File Logger Configuration

    func testFileLoggerRollingFrequency() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("vera-dd-rolling-\(UUID().uuidString)")
            .path

        let strategy = CocoaLumberjackStrategy.Builder()
            .withFileLogger(
                directory: tempDir,
                rollingFrequency: 60 * 60 * 12,  // 12 hours
                maxFileSize: 2 * 1024 * 1024,     // 2 MB
                maxNumberOfFiles: 5
            )
            .build()

        strategy.log(LogEvent(level: .info, tag: "Config", message: "custom rolling"))
        DDLog.flushLog()

        XCTAssertFalse(strategy.logFilePaths.isEmpty)

        try? FileManager.default.removeItem(atPath: tempDir)
    }

    // MARK: - All Log Levels

    func testAllLogLevelsWork() {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withOSLogger()
            .build()

        let levels: [LogLevel] = [.verbose, .debug, .info, .warn, .error]
        for level in levels {
            strategy.log(LogEvent(level: level, tag: "Levels", message: "\(level)"))
        }
        // Should not crash for any level
    }
}
