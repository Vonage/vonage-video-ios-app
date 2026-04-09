//
//  Created by Vonage.
//

import Foundation

/// A logging backend that processes log events.
///
/// Each strategy represents a different log destination (e.g., os.Logger, CocoaLumberjack, file, print).
/// Strategies can optionally filter or transform events before processing them via `shouldLog(_:)`.
///
/// ## Thread Safety
/// Implementations must be safe to call from any thread. The `LoggerComposite` dispatches
/// on a serial queue, but strategies should still avoid internal data races.
public protocol LoggerStrategy: Sendable {

    /// Filters or transforms a log event before it is processed.
    ///
    /// Return the (possibly modified) event to continue processing, or `nil` to skip this event
    /// for this strategy only. Other strategies in the composite are unaffected.
    ///
    /// The default implementation returns the event unchanged.
    ///
    /// - Parameter event: The incoming log event.
    /// - Returns: The event to log, or `nil` to suppress logging for this strategy.
    func shouldLog(_ event: LogEvent) -> LogEvent?

    /// Processes the log event.
    ///
    /// Called only if `shouldLog(_:)` returned a non-nil event.
    ///
    /// - Parameter event: The (possibly transformed) log event.
    func log(_ event: LogEvent)
}

// MARK: - Default Implementation

public extension LoggerStrategy {
    func shouldLog(_ event: LogEvent) -> LogEvent? {
        event
    }
}
