//
//  Created by Vonage on 8/4/26.
//

import Foundation

/// A composite logger that fans out log events to multiple strategies.
///
/// Uses a Swift actor to serialize all log operations.
///
/// ```swift
/// let composite = LoggerComposite(strategies: [
///     OSLogStrategy(),
///     DefaultLogStrategy(),
/// ])
/// await composite.log(event)
/// ```
public actor LoggerComposite {

    private let strategies: [any LoggerStrategy]

    /// Creates a composite logger with the given strategies.
    ///
    /// - Parameter strategies: The logging backends to which log events are dispatched.
    public init(strategies: [any LoggerStrategy]) {
        self.strategies = strategies
    }

    /// Dispatches a log event to all registered strategies.
    ///
    /// Each strategy's `shouldLog(_:)` filter is checked first. If it returns `true`,
    /// the event is passed to the strategy's `log(_:)` method.
    ///
    /// Calls are serialized by the actor, ensuring thread safety.
    ///
    /// - Parameter event: The log event to dispatch.
    public func log(_ event: LogEvent) {
        for strategy in strategies {
            if strategy.shouldLog(event) {
                strategy.log(event)
            }
        }
    }
}
