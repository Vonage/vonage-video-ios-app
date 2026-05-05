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

    /// Waits briefly for fire-and-forget Tasks to be processed by the actor.
    private func waitForDelivery() async throws {
        try await Task.sleep(for: .milliseconds(100))
    }

    // MARK: - Builder Tests

    @Test("Builder creates logger with strategies")
    func builderCreatesLoggerWithStrategies() async throws {
        let (logger, strategy) = makeSUT()

        logger.log(level: .debug, tag: "T", message: "builder test")
        try await waitForDelivery()

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
    func levelMethodsProduceCorrectLevels(testCase: (LogLevel, String)) async throws {
        let (level, msg) = testCase
        let (logger, strategy) = makeSUT()

        logger.log(level: level, tag: "T", message: msg)
        try await waitForDelivery()

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].level == level)
        #expect(strategy.events[0].message == msg)
    }

    // MARK: - Error Handling Tests

    @Test("Error is passed through to strategy")
    func errorIsPassed() async throws {
        let (logger, strategy) = makeSUT()

        let error = NSError(domain: "test", code: 42)
        logger.log(level: .error, tag: "T", message: "failed", error: error)
        try await waitForDelivery()

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].error != nil)
        #expect((strategy.events[0].error as? NSError)?.code == 42)
    }

    @Test("Message without error has nil error")
    func messageWithoutErrorHasNilError() async throws {
        let (logger, strategy) = makeSUT()

        logger.log(level: .info, tag: "T", message: "heartbeat")
        try await waitForDelivery()

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].error == nil)
    }

    // MARK: - Tag Tests

    @Test("Tag is set per call")
    func tagIsSetPerCall() async throws {
        let (logger, strategy) = makeSUT()

        logger.log(level: .info, tag: "TagA", message: "first")
        logger.log(level: .info, tag: "TagB", message: "second")
        try await waitForDelivery()

        #expect(strategy.events.count == 2)
        #expect(strategy.events[0].tag == "TagA")
        #expect(strategy.events[1].tag == "TagB")
    }

    // MARK: - Event Metadata Tests

    @Test("Event contains timestamp and thread")
    func eventContainsTimestampAndThread() async throws {
        let (logger, strategy) = makeSUT()

        let before = Date()
        logger.log(level: .debug, tag: "T", message: "timestamped")
        try await waitForDelivery()
        let after = Date()

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].timestamp >= before)
        #expect(strategy.events[0].timestamp <= after)
        #expect(!strategy.events[0].thread.isEmpty)
    }

    @Test("No strategies does not crash")
    func noStrategiesDoesNotCrash() async throws {
        let logger = VonageLogger.Builder().build()
        logger.log(level: .debug, tag: "T", message: "nothing listening")
        try await waitForDelivery()
    }

    @Test("Multiple strategies all receive events")
    func multipleStrategiesAllReceiveEvents() async throws {
        let strategy1 = CollectingStrategy()
        let strategy2 = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy1)
            .addStrategy(strategy2)
            .build()

        logger.log(level: .info, tag: "T", message: "multi")
        try await waitForDelivery()

        #expect(strategy1.events.count == 1)
        #expect(strategy2.events.count == 1)
    }
}
