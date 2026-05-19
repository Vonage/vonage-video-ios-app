//
//  Created by Vonage on 8/4/26.
//

import Foundation

/// A logging backend that processes log events.
///
/// Each strategy represents a different log destination (e.g., os.Logger, file, print).
/// Strategies can optionally filter events before processing them via `shouldLog(_:)`.
///
/// ## Thread Safety
/// Implementations must be safe to call from any thread. The `LoggerComposite` actor
/// serializes calls, but strategies should still avoid internal data races.
public protocol LoggerStrategy: Sendable {

    /// Determines whether this strategy should process the given event.
    ///
    /// Return `true` to process the event, or `false` to skip it
    /// for this strategy only. Other strategies in the composite are unaffected.
    ///
    /// The default implementation returns `true`.
    ///
    /// - Parameter event: The incoming log event.
    /// - Returns: `true` if this strategy should log the event.
    func shouldLog(_ event: LogEvent) -> Bool

    /// Processes the log event.
    ///
    /// Called only if `shouldLog(_:)` returned `true`.
    ///
    /// - Parameter event: The log event.
    func log(_ event: LogEvent)
}

// MARK: - Default Implementation

extension LoggerStrategy {
    public func shouldLog(_ event: LogEvent) -> Bool {
        true
    }
}
