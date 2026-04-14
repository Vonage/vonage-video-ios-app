//
//  Created by Vonage on 8/4/26.
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

    /// Creates a composite logger with the given strategies.
    ///
    /// - Parameters:
    ///   - strategies: The logging backends to which log events are dispatched.
    ///   - queue: The dispatch queue used for executing logging operations. Defaults to an internal utility queue.
    public init(
        strategies: [any LoggerStrategy],
        queue: DispatchQueue = DispatchQueue(
            label: "com.vonage.VERALogger.composite",
            qos: .utility
        )
    ) {
        self.strategies = strategies
        self.queue = queue
    }

    /// Dispatches a log event to all registered strategies.
    ///
    /// Each strategy's `shouldLog(_:)` filter is checked first. If it returns `true`,
    /// the event is passed to the strategy's `log(_:)` method.
    ///
    /// - Parameter event: The log event to dispatch.
    public func log(_ event: LogEvent) {
        let capturedStrategies = strategies
        queue.async {
            for strategy in capturedStrategies {
                if strategy.shouldLog(event) {
                    strategy.log(event)
                }
            }
        }
    }

    /// Synchronously dispatches a log event. Useful for critical errors or testing.
    ///
    /// - Parameter event: The log event to dispatch.
    public func logSync(_ event: LogEvent) {
        for strategy in strategies {
            if strategy.shouldLog(event) {
                strategy.log(event)
            }
        }
    }
}
