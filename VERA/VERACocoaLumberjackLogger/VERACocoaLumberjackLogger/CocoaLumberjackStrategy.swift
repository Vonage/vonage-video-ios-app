//
//  Created by Vonage on 8/4/26.
//

import CocoaLumberjackSwift
import Foundation
import VERALogger

/// A `LoggerStrategy` that dispatches log events through CocoaLumberjack.
///
/// Each instance owns a dedicated `DDLog` to avoid polluting the global shared logger.
/// Use the ``Builder`` to configure which CocoaLumberjack loggers (OS, file, console) are active.
///
/// ```swift
/// let strategy = CocoaLumberjackStrategy.Builder()
///     .withOSLogger()
///     .withFileLogger(directory: logsDirectory.path)
///     .withConsoleLogger()
///     .build()
///
/// let logger = VonageLogger.Builder()
///     .addStrategy(strategy)
///     .build()
/// ```
public final class CocoaLumberjackStrategy: LoggerStrategy, @unchecked Sendable {

    let ddLog: DDLog

    init(ddLog: DDLog) {
        self.ddLog = ddLog
    }

    public func log(_ event: LogEvent) {
        let formatted = Self.formatMessage(event)
        let ddMessage = DDLogMessage(
            format: "%@",
            args: getVaList([formatted]),
            level: event.level.ddLogLevel,
            flag: event.level.ddLogFlag,
            context: 0,
            file: "",
            function: nil,
            line: 0,
            tag: event.tag,
            options: [.dontCopyMessage],
            timestamp: event.timestamp
        )
        ddLog.log(asynchronous: true, message: ddMessage)
    }

    // MARK: - Message Formatting

    static func formatMessage(_ event: LogEvent) -> String {
        var msg = "[\(event.tag)] \(event.message)"
        if let error = event.error {
            msg += "\n\(error)"
        }
        return msg
    }

    // MARK: - Builder

    /// A builder for constructing a `CocoaLumberjackStrategy` with configured DDLoggers.
    ///
    /// ```swift
    /// let strategy = CocoaLumberjackStrategy.Builder()
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

        /// Builds the strategy with all configured DDLoggers.
        public func build() -> CocoaLumberjackStrategy {
            CocoaLumberjackStrategy(ddLog: ddLog)
        }
    }
}

// MARK: - LogLevel Mapping

extension LogLevel {
    /// The CocoaLumberjack flag corresponding to this level.
    var ddLogFlag: DDLogFlag {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warn: return .warning
        case .error: return .error
        }
    }

    /// The CocoaLumberjack level mask that includes this level and all more severe levels.
    var ddLogLevel: DDLogLevel {
        switch self {
        case .verbose: return .verbose
        case .debug: return .debug
        case .info: return .info
        case .warn: return .warning
        case .error: return .error
        }
    }
}
