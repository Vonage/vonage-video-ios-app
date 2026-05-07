//
//  Created by Vonage on 8/4/26.
//

import CocoaLumberjackSwift
import Foundation
import Testing

@testable import VERACocoaLumberjackLogger

// MARK: - Log Level Tests

@Suite("CocoaLumberjackLogLevel Tests")
struct CocoaLumberjackLogLevelTests {

    @Test("Levels are ordered from verbose to error")
    func ordering() {
        #expect(CocoaLumberjackLogLevel.verbose < .debug)
        #expect(CocoaLumberjackLogLevel.debug < .info)
        #expect(CocoaLumberjackLogLevel.info < .warn)
        #expect(CocoaLumberjackLogLevel.warn < .error)
    }

    @Test(
        "Each level has the correct description",
        arguments: [
            (CocoaLumberjackLogLevel.verbose, "VERBOSE"),
            (.debug, "DEBUG"),
            (.info, "INFO"),
            (.warn, "WARN"),
            (.error, "ERROR"),
        ]
    )
    func descriptions(testCase: (CocoaLumberjackLogLevel, String)) {
        let (level, expected) = testCase
        #expect(level.description == expected)
    }

    @Test("All cases count is 5")
    func allCases() {
        #expect(CocoaLumberjackLogLevel.allCases.count == 5)
    }

    @Test(
        "Each level maps to the correct DDLogFlag",
        arguments: [
            (CocoaLumberjackLogLevel.verbose, DDLogFlag.verbose),
            (.debug, .debug),
            (.info, .info),
            (.warn, .warning),
            (.error, .error),
        ]
    )
    func ddLogFlagMapping(testCase: (CocoaLumberjackLogLevel, DDLogFlag)) {
        let (level, expectedFlag) = testCase
        #expect(level.ddLogFlag == expectedFlag)
    }
}

// MARK: - Builder Tests

@Suite("CocoaLumberjackLogger Builder Tests")
struct CocoaLumberjackLoggerBuilderTests {

    @Test("Builder with no loggers creates a valid logger without crashing")
    func builderWithNoLoggers() {
        let logger = CocoaLumberjackLogger.Builder().build()
        logger.info("Test", "should not crash")
    }

    @Test("withOSLogger adds a DDOSLogger")
    func withOSLogger() {
        let logger = CocoaLumberjackLogger.Builder()
            .withOSLogger()
            .build()

        let loggers = logger.ddLog.allLoggers
        let hasOSLogger = loggers.contains { $0 is DDOSLogger }
        #expect(hasOSLogger)
    }

    @Test("withFileLogger adds a DDFileLogger")
    func withFileLogger() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("cocoalumberjack-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let logger = CocoaLumberjackLogger.Builder()
            .withFileLogger(directory: tempDir.path)
            .build()

        let loggers = logger.ddLog.allLoggers
        let hasFileLogger = loggers.contains { $0 is DDFileLogger }
        #expect(hasFileLogger)
    }

    @Test("withFileLogger without directory uses defaults")
    func withFileLoggerDefaultDir() {
        let logger = CocoaLumberjackLogger.Builder()
            .withFileLogger()
            .build()

        let loggers = logger.ddLog.allLoggers
        let hasFileLogger = loggers.contains { $0 is DDFileLogger }
        #expect(hasFileLogger)
    }

    @Test("withConsoleLogger adds a ConsoleDDLogger")
    func withConsoleLogger() {
        let logger = CocoaLumberjackLogger.Builder()
            .withConsoleLogger()
            .build()

        let loggers = logger.ddLog.allLoggers
        let hasConsoleLogger = loggers.contains { $0 is ConsoleDDLogger }
        #expect(hasConsoleLogger)
    }

    @Test("Builder supports chaining multiple loggers")
    func chainingMultipleLoggers() {
        let logger = CocoaLumberjackLogger.Builder()
            .withOSLogger()
            .withConsoleLogger()
            .build()

        let loggers = logger.ddLog.allLoggers
        #expect(loggers.count == 2)
        #expect(loggers.contains { $0 is DDOSLogger })
        #expect(loggers.contains { $0 is ConsoleDDLogger })
    }
}

// MARK: - Message Formatting Tests

@Suite("CocoaLumberjackLogger Message Formatting Tests")
struct CocoaLumberjackLoggerFormattingTests {

    @Test("Message format includes tag and message")
    func formatMessageWithoutError() {
        let formatted = CocoaLumberjackLogger.formatMessage(
            tag: "MyTag",
            message: "hello world",
            error: nil
        )

        #expect(formatted == "[MyTag] hello world")
    }

    @Test("Message format includes error when present")
    func formatMessageWithError() {
        let error = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "boom"])
        let formatted = CocoaLumberjackLogger.formatMessage(
            tag: "Err",
            message: "failed",
            error: error
        )

        #expect(formatted.contains("[Err] failed"))
        #expect(formatted.contains("boom"))
    }

    @Test("Message without error has no newline")
    func formatMessageWithoutErrorHasNoNewline() {
        let formatted = CocoaLumberjackLogger.formatMessage(
            tag: "Tag",
            message: "msg",
            error: nil
        )

        #expect(!formatted.contains("\n"))
    }
}

// MARK: - Logging Behavior Tests

@Suite("CocoaLumberjackLogger Logging Tests")
struct CocoaLumberjackLoggerLoggingTests {

    private func makeSUT() -> (CocoaLumberjackLogger, DDLoggerSpy) {
        let ddLog = DDLog()
        let spy = DDLoggerSpy()
        ddLog.add(spy, with: .all)
        let logger = CocoaLumberjackLogger(ddLog: ddLog)
        return (logger, spy)
    }

    @Test("Log dispatches message to registered DDLoggers")
    func logDispatchesMessage() async throws {
        let (logger, spy) = makeSUT()

        logger.info("TestTag", "hello world")

        await waitForLogEvents(1, in: spy)

        #expect(spy.messages.count >= 1)
        #expect(spy.messages.first?.message.contains("[TestTag] hello world") == true)
    }

    @Test(
        "Each level method dispatches with the correct DDLogFlag",
        arguments: [
            (CocoaLumberjackLogLevel.verbose, DDLogFlag.verbose),
            (.debug, .debug),
            (.info, .info),
            (.warn, .warning),
            (.error, .error),
        ]
    )
    func levelMethodDispatchesCorrectFlag(testCase: (CocoaLumberjackLogLevel, DDLogFlag)) async {
        let (level, expectedFlag) = testCase
        let (logger, spy) = makeSUT()

        logger.log(level: level, tag: "T", message: "test")

        await waitForLogEvents(1, in: spy)

        #expect(spy.messages.count >= 1)
        #expect(spy.messages.first?.flag == expectedFlag)
    }

    @Test("Error details are included in the dispatched message")
    func errorDetailsIncluded() async {
        let (logger, spy) = makeSUT()

        let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "crash"])
        logger.error("Err", "failure", error: error)

        await waitForLogEvents(1, in: spy)

        #expect(spy.messages.count >= 1)
        #expect(spy.messages.first?.message.contains("[Err] failure") == true)
        #expect(spy.messages.first?.message.contains("crash") == true)
    }

    @Test("Nil error is not appended to the message")
    func nilErrorNotAppended() async {
        let (logger, spy) = makeSUT()

        logger.debug("Tag", "clean message")

        await waitForLogEvents(1, in: spy)

        #expect(spy.messages.count >= 1)
        #expect(spy.messages.first?.message.contains("\n") == false)
    }

    @Test("Tag is passed as DDLogMessage tag")
    func tagIsPassedAsDDLogMessageTag() async {
        let (logger, spy) = makeSUT()

        logger.info("MyModule", "test")

        await waitForLogEvents(1, in: spy)

        #expect(spy.messages.count >= 1)
        #expect(spy.messages.first?.representedObject as? String == "MyModule")
    }

    @Test("Multiple log calls are all dispatched")
    func multipleLogCallsDispatched() async {
        let (logger, spy) = makeSUT()

        logger.info("T", "first")
        logger.info("T", "second")
        logger.info("T", "third")

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
        let logger = CocoaLumberjackLogger(ddLog: ddLog)

        logger.info("Console", "test message")

        // Allow async dispatch to complete
        try? await Task.sleep(for: .milliseconds(100))
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
