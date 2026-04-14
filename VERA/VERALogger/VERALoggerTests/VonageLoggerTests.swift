//
//  Created by Vonage on 8/4/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("VonageLogger Tests")
struct VonageLoggerTests {

    // MARK: - Test Helpers

    private final class CollectingStrategy: LoggerStrategy, @unchecked Sendable {
        private let lock = NSLock()
        private var _events: [LogEvent] = []

        var events: [LogEvent] {
            lock.lock()
            defer { lock.unlock() }
            return _events
        }

        func log(_ event: LogEvent) {
            lock.lock()
            defer { lock.unlock() }
            _events.append(event)
        }
    }

    private func makeSUT() -> (VonageLogger, CollectingStrategy) {
        let strategy = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()
        return (logger, strategy)
    }

    // MARK: - Builder Tests

    @Test("Builder creates logger with strategies")
    func builderCreatesLoggerWithStrategies() {
        let (logger, strategy) = makeSUT()

        logger.logSync(level: .debug, tag: "T", message: "builder test")

        #expect(strategy.events.count == 1)
    }

    // MARK: - Level Method Tests

    @Test(
        "Each level method produces the correct log level",
        arguments: [
            (LogLevel.verbose, "v"),
            (LogLevel.debug, "d"),
            (LogLevel.info, "i"),
            (LogLevel.warn, "w"),
            (LogLevel.error, "e"),
        ]
    )
    func levelMethodsProduceCorrectLevels(testCase: (LogLevel, String)) {
        let (level, msg) = testCase
        let (logger, strategy) = makeSUT()

        logger.logSync(level: level, tag: "T", message: msg)

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].level == level)
        #expect(strategy.events[0].message == msg)
    }

    // MARK: - Error Handling Tests

    @Test("Error is passed through to strategy")
    func errorIsPassed() {
        let (logger, strategy) = makeSUT()

        let error = NSError(domain: "test", code: 42)
        logger.logSync(level: .error, tag: "T", message: "failed", error: error)

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].error != nil)
        #expect((strategy.events[0].error as? NSError)?.code == 42)
    }

    @Test("Message without error has nil error")
    func messageWithoutErrorHasNilError() {
        let (logger, strategy) = makeSUT()

        logger.logSync(level: .info, tag: "T", message: "heartbeat")

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].error == nil)
    }

    // MARK: - Tag Tests

    @Test("Tag is set per call")
    func tagIsSetPerCall() {
        let (logger, strategy) = makeSUT()

        logger.logSync(level: .info, tag: "TagA", message: "first")
        logger.logSync(level: .info, tag: "TagB", message: "second")

        #expect(strategy.events.count == 2)
        #expect(strategy.events[0].tag == "TagA")
        #expect(strategy.events[1].tag == "TagB")
    }

    // MARK: - Event Metadata Tests

    @Test("Event contains timestamp and thread")
    func eventContainsTimestampAndThread() {
        let (logger, strategy) = makeSUT()

        let before = Date()
        logger.logSync(level: .debug, tag: "T", message: "timestamped")
        let after = Date()

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].timestamp >= before)
        #expect(strategy.events[0].timestamp <= after)
        #expect(!strategy.events[0].thread.isEmpty)
    }

    @Test("No strategies does not crash")
    func noStrategiesDoesNotCrash() {
        let logger = VonageLogger.Builder().build()
        logger.logSync(level: .debug, tag: "T", message: "nothing listening")
    }

    @Test("Multiple strategies all receive events")
    func multipleStrategiesAllReceiveEvents() {
        let strategy1 = CollectingStrategy()
        let strategy2 = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy1)
            .addStrategy(strategy2)
            .build()

        logger.logSync(level: .info, tag: "T", message: "multi")

        #expect(strategy1.events.count == 1)
        #expect(strategy2.events.count == 1)
    }
}
