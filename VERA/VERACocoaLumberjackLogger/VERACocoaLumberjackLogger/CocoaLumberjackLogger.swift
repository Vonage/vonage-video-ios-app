//
//  Created by Vonage on 8/4/26.
//

import CocoaLumberjackSwift
import Foundation

/// A logger facade backed by CocoaLumberjack.
///
/// Each instance owns a dedicated `DDLog` instance to avoid polluting the global
/// shared logger. Use the ``Builder`` to configure which CocoaLumberjack loggers
/// (OS, file, console) are active.
///
/// ```swift
/// let logger = CocoaLumberjackLogger.Builder()
///     .withOSLogger()
///     .withFileLogger(directory: logsDirectory.path)
///     .withConsoleLogger()
///     .build()
///
/// logger.debug("MyFeature", "User logged in")
/// logger.error("MyFeature", "Something failed", error: error)
/// ```
public final class CocoaLumberjackLogger: @unchecked Sendable {

    let ddLog: DDLog

    init(ddLog: DDLog) {
        self.ddLog = ddLog
    }

    // MARK: - Convenience Methods

    public func verbose(_ tag: String, _ message: String, error: Error? = nil) {
        log(level: .verbose, tag: tag, message: message, error: error)
    }

    public func debug(_ tag: String, _ message: String, error: Error? = nil) {
        log(level: .debug, tag: tag, message: message, error: error)
    }

    public func info(_ tag: String, _ message: String, error: Error? = nil) {
        log(level: .info, tag: tag, message: message, error: error)
    }

    public func warn(_ tag: String, _ message: String, error: Error? = nil) {
        log(level: .warn, tag: tag, message: message, error: error)
    }

    public func error(_ tag: String, _ message: String, error: Error? = nil) {
        log(level: .error, tag: tag, message: message, error: error)
    }

    /// Logs a message at the given level.
    ///
    /// The message is formatted as `[tag] message` and dispatched asynchronously
    /// through CocoaLumberjack's logging pipeline.
    public func log(level: CocoaLumberjackLogLevel, tag: String, message: String, error: Error? = nil) {
        let formatted = Self.formatMessage(tag: tag, message: message, error: error)
        let ddMessage = DDLogMessage(
            format: "%@",
            args: getVaList([formatted]),
            level: level.ddLogLevel,
            flag: level.ddLogFlag,
            context: 0,
            file: "",
            function: nil,
            line: 0,
            tag: tag,
            options: [.dontCopyMessage],
            timestamp: Date()
        )
        ddLog.log(asynchronous: true, message: ddMessage)
    }

    // MARK: - Message Formatting

    static func formatMessage(tag: String, message: String, error: Error?) -> String {
        var msg = "[\(tag)] \(message)"
        if let error {
            msg += "\n\(error)"
        }
        return msg
    }

    // MARK: - Builder

    /// A builder for constructing a `CocoaLumberjackLogger` with configured DDLoggers.
    ///
    /// ```swift
    /// let logger = CocoaLumberjackLogger.Builder()
    ///     .withOSLogger()
    ///     .withConsoleLogger()
    ///     .build()
    /// ```
    public final class Builder {
        private let ddLog = DDLog()

        public init() {}

        /// Adds a `DDOSLogger` for Apple's unified logging (os_log / Console.app).
        @discardableResult
        public func withOSLogger() -> Builder {
            ddLog.add(DDOSLogger.sharedInstance)
            return self
        }

        /// Adds a `DDFileLogger` that writes logs to rotating files in the given directory.
        ///
        /// - Parameter directory: The directory path for log files. If `nil`, uses the default.
        @discardableResult
        public func withFileLogger(directory: String? = nil) -> Builder {
            let fileLogger: DDFileLogger
            if let directory {
                let manager = DDLogFileManagerDefault(logsDirectory: directory)
                fileLogger = DDFileLogger(logFileManager: manager)
            } else {
                fileLogger = DDFileLogger()
            }
            ddLog.add(fileLogger)
            return self
        }

        /// Adds a ``ConsoleDDLogger`` that writes to standard output via `print()`.
        @discardableResult
        public func withConsoleLogger() -> Builder {
            ddLog.add(ConsoleDDLogger())
            return self
        }

        /// Builds the logger with all configured DDLoggers.
        public func build() -> CocoaLumberjackLogger {
            CocoaLumberjackLogger(ddLog: ddLog)
        }
    }
}
