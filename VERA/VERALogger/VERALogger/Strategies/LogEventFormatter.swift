//
//  Created by Vonage on 8/4/26.
//

import Foundation

/// Formats ``LogEvent`` instances into human-readable log lines.
///
/// Thread-safe: the formatter is immutable after construction.
public struct LogEventFormatter: Sendable {

    private let dateFormatter: DateFormatter

    /// Creates a formatter with the given date formatter.
    ///
    /// - Parameter dateFormatter: Formatter for log line timestamps.
    public init(dateFormatter: DateFormatter) {
        self.dateFormatter = dateFormatter
    }

    /// Formats a log event into a single log line.
    ///
    /// - Parameter event: The log event to format.
    /// - Returns: A human-readable string representation.
    public func format(_ event: LogEvent) -> String {
        let time = dateFormatter.string(from: event.timestamp)
        var line = "\(time) [\(event.thread)] [\(event.level)] \(event.tag): \(event.message)"
        if let error = event.error {
            line += "\n\(error)"
        }
        return line
    }
}
