//
//  Created by Vonage on 8/4/26.
//

import CocoaLumberjackSwift
import Foundation
import Testing
import VERALogger

@testable import VERACocoaLumberjackLogger

// MARK: - Strategy Conformance Tests

@Suite("CocoaLumberjackStrategy Conformance Tests")
struct CocoaLumberjackStrategyConformanceTests {

    @Test("CocoaLumberjackStrategy conforms to LoggerStrategy")
    func conformsToLoggerStrategy() {
        let strategy = CocoaLumberjackStrategy.Builder().build()
        let _: any LoggerStrategy = strategy
    }

    @Test("shouldLog returns true by default")
    func shouldLogReturnsTrue() {
        let strategy = CocoaLumberjackStrategy.Builder().build()
        let event = LogEvent(level: .info, tag: "Test", message: "hello")
        #expect(strategy.shouldLog(event))
    }
}

// MARK: - Builder Tests

@Suite("CocoaLumberjackStrategy Builder Tests")
struct CocoaLumberjackStrategyBuilderTests {

    @Test("Builder with no loggers creates a valid strategy without crashing")
    func builderWithNoLoggers() {
        let strategy = CocoaLumberjackStrategy.Builder().build()
        let event = LogEvent(level: .info, tag: "Test", message: "should not crash")
        strategy.log(event)
    }

    @Test("withOSLogger adds a DDOSLogger")
    func withOSLogger() {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withOSLogger()
            .build()

        let loggers = strategy.ddLog.allLoggers
        let hasOSLogger = loggers.contains { $0 is DDOSLogger }
        #expect(hasOSLogger)
    }

    @Test("withFileLogger adds a DDFileLogger")
    func withFileLogger() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cocoalumberjack-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let strategy = CocoaLumberjackStrategy.Builder()
            .withFileLogger(directory: tempDir.path)
            .build()

        let loggers = strategy.ddLog.allLoggers
        let hasFileLogger = loggers.contains { $0 is DDFileLogger }
        #expect(hasFileLogger)
    }

    @Test("withFileLogger without directory uses defaults")
    func withFileLoggerDefaultDir() {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withFileLogger()
            .build()

        let loggers = strategy.ddLog.allLoggers
        let hasFileLogger = loggers.contains { $0 is DDFileLogger }
        #expect(hasFileLogger)
    }

    @Test("withConsoleLogger adds a ConsoleDDLogger")
    func withConsoleLogger() {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withConsoleLogger()
            .build()

        let loggers = strategy.ddLog.allLoggers
        let hasConsoleLogger = loggers.contains { $0 is ConsoleDDLogger }
        #expect(hasConsoleLogger)
    }

    @Test("Builder supports chaining multiple loggers")
    func chainingMultipleLoggers() {
        let strategy = CocoaLumberjackStrategy.Builder()
            .withOSLogger()
            .withConsoleLogger()
            .build()

        let loggers = strategy.ddLog.allLoggers
        #expect(loggers.count == 2)
        #expect(loggers.contains { $0 is DDOSLogger })
        #expect(loggers.contains { $0 is ConsoleDDLogger })
    }
}

// MARK: - Message Formatting Tests

@Suite("CocoaLumberjackStrategy Message Formatting Tests")
struct CocoaLumberjackStrategyFormattingTests {

    @Test("Message format includes tag and message")
    func formatMessageWithoutError() {
        let event = LogEvent(level: .info, tag: "MyTag", message: "hello world")
        let formatted = CocoaLumberjackStrategy.formatMessage(event)
        #expect(formatted == "[MyTag] hello world")
    }

    @Test("Message format includes error when present")
    func formatMessageWithError() {
        let error = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "boom"])
        let event = LogEvent(level: .error, tag: "Err", message: "failed", error: error)
        let formatted = CocoaLumberjackStrategy.formatMessage(event)

        #expect(formatted.contains("[Err] failed"))
        #expect(formatted.contains("boom"))
    }

    @Test("Message without error has no newline")
    func formatMessageWithoutErrorHasNoNewline() {
        let event = LogEvent(level: .debug, tag: "Tag", message: "msg")
        let formatted = CocoaLumberjackStrategy.formatMessage(event)
        #expect(!formatted.contains("\n"))
    }
}

// MARK: - Level Mapping Tests

@Suite("CocoaLumberjackStrategy Level Mapping Tests")
struct CocoaLumberjackStrategyLevelMappingTests {

    @Test(
        "Each LogLevel maps to the correct DDLogFlag",
        arguments: [
            (LogLevel.verbose, DDLogFlag.verbose),
            (.debug, .debug),
            (.info, .info),
            (.warn, .warning),
            (.error, .error),
        ]
    )
    func ddLogFlagMapping(testCase: (LogLevel, DDLogFlag)) {
        let (level, expectedFlag) = testCase
        #expect(level.ddLogFlag == expectedFlag)
    }

    @Test(
        "Each LogLevel maps to the correct DDLogLevel",
        arguments: [
            (LogLevel.verbose, DDLogLevel.verbose),
            (.debug, .debug),
            (.info, .info),
            (.warn, .warning),
            (.error, .error),
        ]
    )
    func ddLogLevelMapping(testCase: (LogLevel, DDLogLevel)) {
        let (level, expectedLevel) = testCase
        #expect(level.ddLogLevel == expectedLevel)
    }
}

// MARK: - Logging Behavior Tests

@Suite("CocoaLumberjackStrategy Logging Tests")
struct CocoaLumberjackStrategyLoggingTests {

    private func makeSUT() -> (CocoaLumberjackStrategy, DDLoggerSpy) {
        let ddLog = DDLog()
        let spy = DDLoggerSpy()
        ddLog.add(spy, with: .all)
        let strategy = CocoaLumberjackStrategy(ddLog: ddLog)
        return (strategy, spy)
    }

    @Test("Log dispatches message to registered DDLoggers")
    func logDispatchesMessage() async throws {
        let (strategy, spy) = makeSUT()

        let event = LogEvent(level: .info, tag: "TestTag", message: "hello world")
        strategy.log(event)

        await waitForLogEvents(1, in: spy)

        #expect(spy.messages.count >= 1)
        #expect(spy.messages.first?.message.contains("[TestTag] hello world") == true)
    }

    @Test(
        "Each level dispatches with the correct DDLogFlag",
        arguments: [
            (LogLevel.verbose, DDLogFlag.verbose),
            (.debug, .debug),
            (.info, .info),
            (.warn, .warning),
            (.error, .error),
        ]
    )
    func levelDispatchesCorrectFlag(testCase: (LogLevel, DDLogFlag)) async {
        let (level, expectedFlag) = testCase
        let (strategy, spy) = makeSUT()

        let event = LogEvent(level: level, tag: "T", message: "test")
        strategy.log(event)

        await waitForLogEvents(1, in: spy)

        #expect(spy.messages.count >= 1)
        #expect(spy.messages.first?.flag == expectedFlag)
    }

    @Test("Error details are included in the dispatched message")
    func errorDetailsIncluded() async {
        let (strategy, spy) = makeSUT()

        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "crash"])
        let event = LogEvent(level: .error, tag: "Err", message: "failure", error: error)
        strategy.log(event)

        await waitForLogEvents(1, in: spy)

        #expect(spy.messages.count >= 1)
        #expect(spy.messages.first?.message.contains("[Err] failure") == true)
        #expect(spy.messages.first?.message.contains("crash") == true)
    }

    @Test("Tag is passed as DDLogMessage tag")
    func tagIsPassedAsDDLogMessageTag() async {
        let (strategy, spy) = makeSUT()

        let event = LogEvent(level: .info, tag: "MyModule", message: "test")
        strategy.log(event)

        await waitForLogEvents(1, in: spy)

        #expect(spy.messages.count >= 1)
        #expect(spy.messages.first?.representedObject as? String == "MyModule")
    }

    @Test("Multiple log calls are all dispatched")
    func multipleLogCallsDispatched() async {
        let (strategy, spy) = makeSUT()

        strategy.log(LogEvent(level: .info, tag: "T", message: "first"))
        strategy.log(LogEvent(level: .info, tag: "T", message: "second"))
        strategy.log(LogEvent(level: .info, tag: "T", message: "third"))

        await waitForLogEvents(3, in: spy)

        #expect(spy.messages.count >= 3)
    }

    // MARK: - Helpers

    private func waitForLogEvents(
        _ expectedCount: Int,
        in spy: DDLoggerSpy,
        timeout: Duration = .seconds(2)
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)

        while clock.now < deadline {
            if spy.messages.count >= expectedCount {
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}

// MARK: - ConsoleDDLogger Tests

@Suite("ConsoleDDLogger Tests")
struct ConsoleDDLoggerTests {

    @Test("ConsoleDDLogger does not crash when logging a message")
    func doesNotCrash() async {
        let ddLog = DDLog()
        let consoleLogger = ConsoleDDLogger()
        ddLog.add(consoleLogger, with: .all)
        let strategy = CocoaLumberjackStrategy(ddLog: ddLog)

        let event = LogEvent(level: .info, tag: "Console", message: "test message")
        strategy.log(event)

        try? await Task.sleep(for: .milliseconds(100))
    }
}

// MARK: - Integration with VonageLogger

@Suite("CocoaLumberjackStrategy Integration Tests")
struct CocoaLumberjackStrategyIntegrationTests {

    @Test("Strategy works when added to VonageLogger")
    func worksWithVonageLogger() async {
        let ddLog = DDLog()
        let spy = DDLoggerSpy()
        ddLog.add(spy, with: .all)
        let strategy = CocoaLumberjackStrategy(ddLog: ddLog)

        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()

        logger.info("Integration", "hello from VonageLogger")

        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(2))
        while clock.now < deadline {
            if spy.messages.count >= 1 { break }
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(spy.messages.count >= 1)
        #expect(spy.messages.first?.message.contains("[Integration] hello from VonageLogger") == true)
    }
}

// MARK: - Test Helpers

/// A spy DDAbstractLogger subclass that records all messages it receives.
private final class DDLoggerSpy: DDAbstractLogger, @unchecked Sendable {

    struct Entry {
        let message: String
        let flag: DDLogFlag
        let representedObject: Any?
    }

    private let lock = NSLock()
    private var _messages: [Entry] = []

    var messages: [Entry] {
        lock.withLock { _messages }
    }

    override func log(message logMessage: DDLogMessage) {
        lock.withLock {
            _messages.append(
                Entry(
                    message: logMessage.message,
                    flag: logMessage.flag,
                    representedObject: logMessage.representedObject
                )
            )
        }
    }
}
