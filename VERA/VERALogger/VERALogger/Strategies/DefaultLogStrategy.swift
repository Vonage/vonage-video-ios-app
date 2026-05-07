//
//  Created by Vonage on 8/4/26.
//

import Foundation

// swiftlint:disable no_print
/// A simple fallback logging strategy that uses `print()`.
///
/// Useful for development, playgrounds, or environments where
/// os.Logger and CocoaLumberjack are unavailable.
public struct DefaultLogStrategy: LoggerStrategy, Sendable {

    private final class FormatterStorage: @unchecked Sendable {
        private let formatter: DateFormatter
        private let lock = NSLock()

        init(dateFormat: String) {
            let formatter = DateFormatter()
            formatter.dateFormat = dateFormat
            formatter.locale = Locale(identifier: "en_US_POSIX")
            self.formatter = formatter
        }

        func string(from date: Date) -> String {
            lock.lock()
            defer { lock.unlock() }
            return formatter.string(from: date)
        }
    }

    private let formatterStorage: FormatterStorage

    /// Creates a default (print-based) log strategy.
    ///
    /// - Parameter dateFormat: The date format string for timestamps.
    ///   Defaults to `"yyyy-MM-dd HH:mm:ss.SSS"`.
    public init(dateFormat: String = "yyyy-MM-dd HH:mm:ss.SSS") {
        formatterStorage = FormatterStorage(dateFormat: dateFormat)
    }

    public func log(_ event: LogEvent) {
        let formatted = formatEvent(event)
        print(formatted)
    }

    /// Formats a log event into a human-readable string.
    ///
    /// Visible for testing.
    internal func formatEvent(_ event: LogEvent) -> String {
        let time = formatterStorage.string(from: event.timestamp)
        var line = "\(time) [\(event.thread)] [\(event.level)] \(event.tag): \(event.message)"
        if let error = event.error {
            line += "\n\(error)"
        }
        return line
    }
}
