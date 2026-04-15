//
//  Created by Vonage on 8/4/26.
//

import Foundation
import Testing

@testable import VERALogger

@Suite("LoggerComposite Tests")
struct LoggerCompositeTests {
    private static let asyncDispatchTimeout: DispatchTimeInterval = .seconds(1)

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
    func logDispatchesToAllStrategies() {
        let strategy1 = CollectingStrategy()
        let strategy2 = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy1, strategy2])

        let event = LogEvent(level: .debug, tag: "Test", message: "hello")
        composite.logSync(event)

        #expect(strategy1.events.count == 1)
        #expect(strategy2.events.count == 1)
        #expect(strategy1.events[0].message == "hello")
    }

    @Test("Log preserves event fields")
    func logPreservesEventFields() {
        let strategy = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy])

        let event = LogEvent(level: .error, tag: "MyTag", message: "test msg")
        composite.logSync(event)

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].level == .error)
        #expect(strategy.events[0].tag == "MyTag")
        #expect(strategy.events[0].message == "test msg")
    }

    @Test("Filter blocks event from strategy")
    func filterBlocksEvent() {
        let blocker = BlockingStrategy()
        let composite = LoggerComposite(strategies: [blocker])

        let event = LogEvent(level: .debug, tag: "T", message: "should be blocked")
        composite.logSync(event)

        #expect(blocker.events.isEmpty)
    }

    @Test("Filter on one strategy does not affect others")
    func filterOnOneStrategyDoesNotAffectOthers() {
        let blocker = BlockingStrategy()
        let collector = CollectingStrategy()
        let composite = LoggerComposite(strategies: [blocker, collector])

        let event = LogEvent(level: .info, tag: "T", message: "partial")
        composite.logSync(event)

        #expect(blocker.events.isEmpty)
        #expect(collector.events.count == 1)
    }

    @Test("Error-only filter passes errors and skips others")
    func errorOnlyFilter() {
        let errorOnly = ErrorOnlyStrategy()
        let composite = LoggerComposite(strategies: [errorOnly])

        composite.logSync(LogEvent(level: .debug, tag: "T", message: "should skip"))
        composite.logSync(LogEvent(level: .error, tag: "T", message: "should pass"))

        #expect(errorOnly.events.count == 1)
        #expect(errorOnly.events[0].level == .error)
    }

    @Test("Empty strategies does not crash")
    func noStrategiesDoesNotCrash() {
        let composite = LoggerComposite(strategies: [])
        let event = LogEvent(level: .debug, tag: "T", message: "no listeners")

        composite.logSync(event)
    }

    @Test("Multiple events are all dispatched")
    func multipleEventsAreAllDispatched() {
        let strategy = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy])

        for i in 0..<5 {
            composite.logSync(LogEvent(level: .info, tag: "T", message: "msg \(i)"))
        }

        #expect(strategy.events.count == 5)
    }

    @Test(
        "All log levels are dispatched",
        arguments: [LogLevel.verbose, .debug, .info, .warn, .error]
    )
    func allLogLevelsAreDispatched(level: LogLevel) {
        let strategy = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy])

        composite.logSync(LogEvent(level: level, tag: "T", message: "\(level)"))

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].level == level)
    }

    // MARK: - Custom Queue Tests

    @Test("Async log dispatches on custom queue")
    func asyncLogDispatchesOnCustomQueue() async {
        let customQueue = DispatchQueue(label: "com.vonage.VERALogger.test.custom", qos: .userInitiated)
        let strategy = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy], queue: customQueue)

        let event = LogEvent(level: .info, tag: "Queue", message: "custom queue")
        composite.log(event)

        // Wait for the async dispatch to complete
        await withCheckedContinuation { continuation in
            customQueue.async {
                continuation.resume()
            }
        }

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].message == "custom queue")
    }

    @Test("Custom queue preserves serial ordering")
    func customQueuePreservesSerialOrdering() async {
        let customQueue = DispatchQueue(label: "com.vonage.VERALogger.test.ordering")
        let strategy = CollectingStrategy()
        let composite = LoggerComposite(strategies: [strategy], queue: customQueue)

        for i in 0..<10 {
            composite.log(LogEvent(level: .info, tag: "T", message: "msg \(i)"))
        }

        await withCheckedContinuation { continuation in
            customQueue.async {
                continuation.resume()
            }
        }

        #expect(strategy.events.count == 10)
        for i in 0..<10 {
            #expect(strategy.events[i].message == "msg \(i)")
        }
    }

    @Test("Default queue works without explicit queue parameter")
    func defaultQueueWorks() {
        let strategy = CollectingStrategy()
        let eventProcessed = DispatchSemaphore(value: 0)
        let verifyingStrategy = CallbackStrategy {
            eventProcessed.signal()
        }
        let signalingComposite = LoggerComposite(strategies: [strategy, verifyingStrategy])

        signalingComposite.log(LogEvent(level: .debug, tag: "T", message: "default queue"))

        let waitResult = eventProcessed.wait(timeout: .now() + Self.asyncDispatchTimeout)
        #expect(waitResult == .success)

        #expect(strategy.events.count == 1)
        #expect(strategy.events[0].message == "default queue")
    }

    private final class CallbackStrategy: LoggerStrategy, @unchecked Sendable {
        private let callback: @Sendable () -> Void

        init(callback: @escaping @Sendable () -> Void) {
            self.callback = callback
        }

        func log(_ event: LogEvent) {
            callback()
        }
    }
}
