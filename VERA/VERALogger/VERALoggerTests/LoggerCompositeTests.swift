//
//  Created by Vonage.
//

@testable import VERALogger
import XCTest

final class LoggerCompositeTests: XCTestCase {

    // MARK: - Helpers

    /// A test strategy that records all events it receives.
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

    /// A test strategy that blocks events.
    private final class BlockingStrategy: LoggerStrategy, @unchecked Sendable {
        private let lock = NSLock()
        private var _events: [LogEvent] = []

        var events: [LogEvent] {
            lock.lock()
            defer { lock.unlock() }
            return _events
        }

        func shouldLog(_ event: LogEvent) -> LogEvent? {
            nil
        }

        func log(_ event: LogEvent) {
            lock.lock()
            defer { lock.unlock() }
            _events.append(event)
        }
    }

    /// A test strategy that transforms the tag.
    private final class TransformingStrategy: LoggerStrategy, @unchecked Sendable {
        private let lock = NSLock()
        private var _events: [LogEvent] = []

        var events: [LogEvent] {
            lock.lock()
            defer { lock.unlock() }
            return _events
        }

        func shouldLog(_ event: LogEvent) -> LogEvent? {
            event.copy(tag: "Transformed")
        }

        func log(_ event: LogEvent) {
            lock.lock()
            defer { lock.unlock() }
            _events.append(event)
        }
    }

    // MARK: - Tests

    func testLogDispatchesToAllStrategies() {
        let strategy1 = CollectingStrategy()
        let strategy2 = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy1, strategy2])

        let event = LogEvent(level: .debug, tag: "Test", message: "hello")
        composite.logSync(event)

        XCTAssertEqual(strategy1.events.count, 1)
        XCTAssertEqual(strategy2.events.count, 1)
        XCTAssertEqual(strategy1.events[0].message, "hello")
    }

    func testLogPreservesEventFields() {
        let strategy = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy])

        let event = LogEvent(level: .error, tag: "MyTag", message: "test msg")
        composite.logSync(event)

        XCTAssertEqual(strategy.events.count, 1)
        XCTAssertEqual(strategy.events[0].level, .error)
        XCTAssertEqual(strategy.events[0].tag, "MyTag")
        XCTAssertEqual(strategy.events[0].message, "test msg")
    }

    func testFilterBlocksEvent() {
        let blocker = BlockingStrategy()
        let composite = LoggerComposite(strategies: [blocker])

        let event = LogEvent(level: .debug, tag: "T", message: "should be blocked")
        composite.logSync(event)

        XCTAssertTrue(blocker.events.isEmpty)
    }

    func testFilterOnOneStrategyDoesNotAffectOthers() {
        let blocker = BlockingStrategy()
        let collector = CollectingStrategy()
        let composite = LoggerComposite(strategies: [blocker, collector])

        let event = LogEvent(level: .info, tag: "T", message: "partial")
        composite.logSync(event)

        XCTAssertTrue(blocker.events.isEmpty)
        XCTAssertEqual(collector.events.count, 1)
    }

    func testTransformHookModifiesEvent() {
        let transformer = TransformingStrategy()
        let composite = LoggerComposite(strategies: [transformer])

        let event = LogEvent(level: .debug, tag: "Original", message: "test")
        composite.logSync(event)

        XCTAssertEqual(transformer.events.count, 1)
        XCTAssertEqual(transformer.events[0].tag, "Transformed")
    }

    func testNoStrategiesDoesNotCrash() {
        let composite = LoggerComposite(strategies: [])
        let event = LogEvent(level: .debug, tag: "T", message: "no listeners")

        composite.logSync(event)
        // Should not crash
    }

    func testMultipleEventsAreAllDispatched() {
        let strategy = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy])

        for i in 0..<5 {
            composite.logSync(LogEvent(level: .info, tag: "T", message: "msg \(i)"))
        }

        XCTAssertEqual(strategy.events.count, 5)
    }

    func testAllLogLevelsAreDispatched() {
        let strategy = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy])

        let levels: [LogLevel] = [.verbose, .debug, .info, .warn, .error]
        for level in levels {
            composite.logSync(LogEvent(level: level, tag: "T", message: "\(level)"))
        }

        XCTAssertEqual(strategy.events.count, 5)
        XCTAssertEqual(strategy.events.map(\.level), levels)
    }
}
