//
//  Created by Vonage on 8/4/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("LoggerComposite Tests")
struct LoggerCompositeTests {

    // MARK: - Test Helpers

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

    /// A test strategy that blocks all events.
    private final class BlockingStrategy: LoggerStrategy, @unchecked Sendable {
        private let lock = NSLock()
        private var _events: [LogEvent] = []

        var events: [LogEvent] {
            lock.lock()
            defer { lock.unlock() }
            return _events
        }

        func shouldLog(_ event: LogEvent) -> Bool {
            false
        }

        func log(_ event: LogEvent) {
            lock.lock()
            defer { lock.unlock() }
            _events.append(event)
        }
    }

    /// A test strategy that only accepts error-level events.
    private final class ErrorOnlyStrategy: LoggerStrategy, @unchecked Sendable {
        private let lock = NSLock()
        private var _events: [LogEvent] = []

        var events: [LogEvent] {
            lock.lock()
            defer { lock.unlock() }
            return _events
        }

        func shouldLog(_ event: LogEvent) -> Bool {
            event.level >= .error
        }

        func log(_ event: LogEvent) {
            lock.lock()
            defer { lock.unlock() }
            _events.append(event)
        }
    }

    // MARK: - Dispatch Tests

    @Test("Log dispatches to all strategies")
    func logDispatchesToAllStrategies() async {
        let strategy1 = CollectingStrategy()
        let strategy2 = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy1, strategy2])

        let event = LogEvent(level: .debug, tag: "Test", message: "hello")
        await composite.log(event)

        #expect(strategy1.events.count == 1)
        #expect(strategy2.events.count == 1)
        #expect(strategy1.events[0].message == "hello")
    }

    @Test("Log preserves event fields")
    func logPreservesEventFields() async {
        let strategy = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy])

        let event = LogEvent(level: .error, tag: "MyTag", message: "test msg")
        await composite.log(event)

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].level == .error)
        #expect(strategy.events[0].tag == "MyTag")
        #expect(strategy.events[0].message == "test msg")
    }

    @Test("Filter blocks event from strategy")
    func filterBlocksEvent() async {
        let blocker = BlockingStrategy()
        let composite = LoggerComposite(strategies: [blocker])

        let event = LogEvent(level: .debug, tag: "T", message: "should be blocked")
        await composite.log(event)

        #expect(blocker.events.isEmpty)
    }

    @Test("Filter on one strategy does not affect others")
    func filterOnOneStrategyDoesNotAffectOthers() async {
        let blocker = BlockingStrategy()
        let collector = CollectingStrategy()
        let composite = LoggerComposite(strategies: [blocker, collector])

        let event = LogEvent(level: .info, tag: "T", message: "partial")
        await composite.log(event)

        #expect(blocker.events.isEmpty)
        #expect(collector.events.count == 1)
    }

    @Test("Error-only filter passes errors and skips others")
    func errorOnlyFilter() async {
        let errorOnly = ErrorOnlyStrategy()
        let composite = LoggerComposite(strategies: [errorOnly])

        await composite.log(LogEvent(level: .debug, tag: "T", message: "should skip"))
        await composite.log(LogEvent(level: .error, tag: "T", message: "should pass"))

        #expect(errorOnly.events.count == 1)
        #expect(errorOnly.events[0].level == .error)
    }

    @Test("Empty strategies does not crash")
    func noStrategiesDoesNotCrash() async {
        let composite = LoggerComposite(strategies: [])
        let event = LogEvent(level: .debug, tag: "T", message: "no listeners")

        await composite.log(event)
    }

    @Test("Multiple events are all dispatched")
    func multipleEventsAreAllDispatched() async {
        let strategy = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy])

        for i in 0..<5 {
            await composite.log(LogEvent(level: .info, tag: "T", message: "msg \(i)"))
        }

        #expect(strategy.events.count == 5)
    }

    @Test(
        "All log levels are dispatched",
        arguments: [LogLevel.verbose, .debug, .info, .warn, .error]
    )
    func allLogLevelsAreDispatched(level: LogLevel) async {
        let strategy = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy])

        await composite.log(LogEvent(level: level, tag: "T", message: "\(level)"))

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].level == level)
    }

    // MARK: - Serialization Tests

    @Test("Actor preserves serial ordering")
    func actorPreservesSerialOrdering() async {
        let strategy = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy])

        for i in 0..<10 {
            await composite.log(LogEvent(level: .info, tag: "T", message: "msg \(i)"))
        }

        #expect(strategy.events.count == 10)
        for i in 0..<10 {
            #expect(strategy.events[i].message == "msg \(i)")
        }
    }
}
