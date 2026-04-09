//
//  Created by Vonage.
//

import Foundation

/// A composite logger that fans out log events to multiple strategies.
///
/// Thread-safe: all logging is dispatched to a dedicated serial queue.
///
/// ```swift
/// let composite = LoggerComposite(strategies: [
///     OSLogStrategy(),
///     DefaultLogStrategy(),
/// ])
/// composite.log(event)
/// ```
public final class LoggerComposite: @unchecked Sendable {

    private let strategies: [any LoggerStrategy]
    private let queue: DispatchQueue

    /// Creates a composite with the given strategies.
    ///
    /// - Parameter strategies: The logging backends to dispatch events to.
    public init(strategies: [any LoggerStrategy]) {
        self.strategies = strategies
        self.queue = DispatchQueue(label: "com.vonage.VERALogger.composite", qos: .utility)
    }

    /// Dispatches a log event to all registered strategies.
    ///
    /// Each strategy's `shouldLog(_:)` filter is checked first. If it returns a non-nil event,
    /// the (possibly transformed) event is passed to the strategy's `log(_:)` method.
    ///
    /// - Parameter event: The log event to dispatch.
    public func log(_ event: LogEvent) {
        let capturedStrategies = strategies
        queue.async {
            for strategy in capturedStrategies {
                if let filteredEvent = strategy.shouldLog(event) {
                    strategy.log(filteredEvent)
                }
            }
        }
    }

    /// Synchronously dispatches a log event. Useful for critical errors or testing.
    ///
    /// - Parameter event: The log event to dispatch.
    public func logSync(_ event: LogEvent) {
        for strategy in strategies {
            if let filteredEvent = strategy.shouldLog(event) {
                strategy.log(filteredEvent)
            }
        }
    }
}
