//
//  Created by Vonage.
//

@testable import VERALogger
import XCTest

final class VonageLoggerTests: XCTestCase {

    // MARK: - Helpers

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

    // MARK: - Tests

    func testBuilderCreatesLoggerWithStrategies() {
        let strategy = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()

        logger.logSync(level: .debug, tag: "T", message: "builder test")

        XCTAssertEqual(strategy.events.count, 1)
    }

    func testDebugMethod() {
        let strategy = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()

        logger.logSync(level: .debug, tag: "T", message: "debug")

        XCTAssertEqual(strategy.events[0].level, .debug)
        XCTAssertEqual(strategy.events[0].message, "debug")
    }

    func testInfoMethod() {
        let strategy = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()

        logger.logSync(level: .info, tag: "T", message: "info")

        XCTAssertEqual(strategy.events[0].level, .info)
    }

    func testWarnMethod() {
        let strategy = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()

        logger.logSync(level: .warn, tag: "T", message: "warn")

        XCTAssertEqual(strategy.events[0].level, .warn)
    }

    func testErrorMethod() {
        let strategy = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()

        logger.logSync(level: .error, tag: "T", message: "error")

        XCTAssertEqual(strategy.events[0].level, .error)
    }

    func testVerboseMethod() {
        let strategy = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()

        logger.logSync(level: .verbose, tag: "T", message: "verbose")

        XCTAssertEqual(strategy.events[0].level, .verbose)
    }

    func testAllLevelMethodsProduceCorrectLevels() {
        let strategy = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()

        logger.logSync(level: .verbose, tag: "T", message: "v")
        logger.logSync(level: .debug, tag: "T", message: "d")
        logger.logSync(level: .info, tag: "T", message: "i")
        logger.logSync(level: .warn, tag: "T", message: "w")
        logger.logSync(level: .error, tag: "T", message: "e")

        XCTAssertEqual(strategy.events.count, 5)
        XCTAssertEqual(strategy.events[0].level, .verbose)
        XCTAssertEqual(strategy.events[1].level, .debug)
        XCTAssertEqual(strategy.events[2].level, .info)
        XCTAssertEqual(strategy.events[3].level, .warn)
        XCTAssertEqual(strategy.events[4].level, .error)
    }

    func testErrorIsPassed() {
        let strategy = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()

        let error = NSError(domain: "test", code: 42)
        logger.logSync(level: .error, tag: "T", message: "failed", error: error)

        XCTAssertEqual(strategy.events.count, 1)
        XCTAssertNotNil(strategy.events[0].error)
        XCTAssertEqual((strategy.events[0].error as? NSError)?.code, 42)
    }

    func testMessageWithoutErrorHasNilError() {
        let strategy = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()

        logger.logSync(level: .info, tag: "T", message: "heartbeat")

        XCTAssertEqual(strategy.events.count, 1)
        XCTAssertNil(strategy.events[0].error)
    }

    func testTagIsSetPerCall() {
        let strategy = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()

        logger.logSync(level: .info, tag: "TagA", message: "first")
        logger.logSync(level: .info, tag: "TagB", message: "second")

        XCTAssertEqual(strategy.events.count, 2)
        XCTAssertEqual(strategy.events[0].tag, "TagA")
        XCTAssertEqual(strategy.events[1].tag, "TagB")
    }

    func testEventContainsTimestampAndThread() {
        let strategy = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy)
            .build()

        let before = Date()
        logger.logSync(level: .debug, tag: "T", message: "timestamped")
        let after = Date()

        XCTAssertEqual(strategy.events.count, 1)
        XCTAssertGreaterThanOrEqual(strategy.events[0].timestamp, before)
        XCTAssertLessThanOrEqual(strategy.events[0].timestamp, after)
        XCTAssertFalse(strategy.events[0].thread.isEmpty)
    }

    func testNoStrategiesDoesNotCrash() {
        let logger = VonageLogger.Builder().build()
        logger.logSync(level: .debug, tag: "T", message: "nothing listening")
        // Should not crash
    }

    func testMultipleStrategiesAllReceiveEvents() {
        let strategy1 = CollectingStrategy()
        let strategy2 = CollectingStrategy()
        let logger = VonageLogger.Builder()
            .addStrategy(strategy1)
            .addStrategy(strategy2)
            .build()

        logger.logSync(level: .info, tag: "T", message: "multi")

        XCTAssertEqual(strategy1.events.count, 1)
        XCTAssertEqual(strategy2.events.count, 1)
    }
}
