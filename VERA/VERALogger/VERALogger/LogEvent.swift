//
//  Created by Vonage on 8/4/26.
//

import Foundation

/// Represents a single log entry with full context.
///
/// Immutable and `Sendable` for safe cross-thread use.
public struct LogEvent: Sendable {
    /// The severity level of this event.
    public let level: LogLevel

    /// A short identifier for the source of the log (e.g., module or class name).
    public let tag: String

    /// The human-readable log message.
    public let message: String

    /// An optional error associated with this event.
    public let error: Error?

    /// The timestamp when this event was created.
    public let timestamp: Date

    /// The name of the thread that created this event.
    public let thread: String

    public init(
        level: LogLevel,
        tag: String,
        message: String,
        error: Error? = nil,
        timestamp: Date = Date(),
        thread: String = {
            let name = Thread.current.name ?? ""
            return name.isEmpty ? Thread.isMainThread ? "main" : "unknown" : name
        }()
    ) {
        self.level = level
        self.tag = tag
        self.message = message
        self.error = error
        self.timestamp = timestamp
        self.thread = thread
    }

    /// Returns a copy of this event with optional field overrides, preserving the current error.
    public func copy(
        level: LogLevel? = nil,
        tag: String? = nil,
        message: String? = nil,
        timestamp: Date? = nil,
        thread: String? = nil
    ) -> LogEvent {
        copy(
            level: level,
            tag: tag,
            message: message,
            error: self.error,
            timestamp: timestamp,
            thread: thread
        )
    }

    /// Returns a copy of this event with optional field overrides.
    ///
    /// Pass `nil` to clear the current error.
    public func copy(
        level: LogLevel? = nil,
        tag: String? = nil,
        message: String? = nil,
        error: Error?,
        timestamp: Date? = nil,
        thread: String? = nil
    ) -> LogEvent {
        makeCopy(
            level: level,
            tag: tag,
            message: message,
            error: error,
            timestamp: timestamp,
            thread: thread
        )
    }

    private func makeCopy(
        level: LogLevel? = nil,
        tag: String? = nil,
        message: String? = nil,
        error: Error?,
        timestamp: Date? = nil,
        thread: String? = nil
    ) -> LogEvent {
        LogEvent(
            level: level ?? self.level,
            tag: tag ?? self.tag,
            message: message ?? self.message,
            error: error,
            timestamp: timestamp ?? self.timestamp,
            thread: thread ?? self.thread
        )
    }
}
