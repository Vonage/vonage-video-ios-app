//
//  Created by Vonage on 8/4/26.
//

import CocoaLumberjackSwift
import Foundation

/// A logging strategy that uses CocoaLumberjack for log output.
///
/// CocoaLumberjack provides advanced features like file logging with rolling,
/// custom formatters, and multiple output targets (OS log, console, file).
///
/// ## Quick Start
///
/// ```swift
/// // Simple — OS log only (same as before):
/// CocoaLumberjackStrategy()
///
/// // Full setup — OS log + file logging + console:
/// CocoaLumberjackStrategy.Builder()
///     .withOSLogger()
///     .withFileLogger(rollingFrequency: 86400, maxNumberOfFiles: 7)
///     .withConsoleLogger()
///     .build()
///
/// // Convenience factories:
/// CocoaLumberjackStrategy.full()
/// CocoaLumberjackStrategy.withFileLogging()
/// ```
public final class CocoaLumberjackStrategy: LoggerStrategy, @unchecked Sendable {

    private let fileLogger: DDFileLogger?

    // MARK: - Backward-Compatible Init

    /// Creates a CocoaLumberjack logging strategy with basic configuration.
    ///
    /// - Parameter configureDefaults: If `true`, automatically adds `DDOSLogger` on first use.
    ///   Set to `false` if you configure CocoaLumberjack loggers yourself.
    public convenience init(configureDefaults: Bool = true) {
        self.init(fileLogger: nil)
        if configureDefaults {
            DDLog.add(DDOSLogger.sharedInstance)
        }
    }

    private init(fileLogger: DDFileLogger?) {
        self.fileLogger = fileLogger
    }

    // MARK: - LoggerStrategy

    public func log(_ event: LogEvent) {
        let msg = formatMessage(event)
        switch event.level {
        case .verbose:
            DDLogVerbose("\(msg)")
        case .debug:
            DDLogDebug("\(msg)")
        case .info:
            DDLogInfo("\(msg)")
        case .warn:
            DDLogWarn("\(msg)")
        case .error:
            DDLogError("\(msg)")
        }
    }

    private func formatMessage(_ event: LogEvent) -> String {
        var msg = "[\(event.tag)] \(event.message)"
        if let error = event.error {
            msg += "\n\(error)"
        }
        return msg
    }

    // MARK: - Log File Access

    /// The file paths of all current CocoaLumberjack log files.
    ///
    /// Returns an empty array if no file logger is configured.
    /// Use this to share or display log files from the app.
    ///
    /// ```swift
    /// let paths = strategy.logFilePaths
    /// let urls = paths.map { URL(fileURLWithPath: $0) }
    /// ```
    public var logFilePaths: [String] {
        fileLogger?.logFileManager.sortedLogFilePaths ?? []
    }

    /// The URLs of all current CocoaLumberjack log files.
    ///
    /// Returns an empty array if no file logger is configured.
    public var logFileURLs: [URL] {
        logFilePaths.map { URL(fileURLWithPath: $0) }
    }

    // MARK: - Convenience Factories

    /// Creates a strategy that only logs to Apple's unified logging system (Console.app).
    public static func osOnly(formatter: DDLogFormatter? = nil) -> CocoaLumberjackStrategy {
        Builder()
            .withOSLogger(formatter: formatter)
            .build()
    }

    /// Creates a strategy with OS logging and file logging.
    ///
    /// - Parameters:
    ///   - directory: Custom directory for log files. Defaults to CocoaLumberjack's default.
    ///   - rollingFrequency: How often to roll to a new file in seconds. Default: 24 hours.
    ///   - maxFileSize: Maximum size per file in bytes. Default: 5 MB.
    ///   - maxNumberOfFiles: Maximum number of archived files. Default: 7.
    ///   - formatter: Optional log formatter. Defaults to CocoaLumberjack's built-in formatter.
    public static func withFileLogging(
        directory: String? = nil,
        rollingFrequency: TimeInterval = 60 * 60 * 24,
        maxFileSize: UInt64 = 5 * 1024 * 1024,
        maxNumberOfFiles: UInt = 7,
        formatter: DDLogFormatter? = nil
    ) -> CocoaLumberjackStrategy {
        let builder = Builder()
            .withOSLogger(formatter: formatter)
            .withFileLogger(
                directory: directory,
                rollingFrequency: rollingFrequency,
                maxFileSize: maxFileSize,
                maxNumberOfFiles: maxNumberOfFiles,
                formatter: formatter
            )
        return builder.build()
    }

    /// Creates a strategy with all available loggers: OS, file, and console.
    ///
    /// - Parameter formatter: Optional log formatter applied to all loggers. Defaults to CocoaLumberjack's built-in formatter.
    public static func full(formatter: DDLogFormatter? = nil) -> CocoaLumberjackStrategy {
        Builder()
            .withOSLogger(formatter: formatter)
            .withFileLogger(formatter: formatter)
            .withConsoleLogger(formatter: formatter)
            .build()
    }

    // MARK: - Builder

    /// A builder for constructing a `CocoaLumberjackStrategy` with fine-grained control
    /// over which CocoaLumberjack loggers are active.
    ///
    /// ```swift
    /// let strategy = CocoaLumberjackStrategy.Builder()
    ///     .withOSLogger()
    ///     .withFileLogger(
    ///         rollingFrequency: 60 * 60 * 12,  // 12 hours
    ///         maxFileSize: 2 * 1024 * 1024,     // 2 MB
    ///         maxNumberOfFiles: 5
    ///     )
    ///     .withConsoleLogger()
    ///     .build()
    /// ```
    public final class Builder {
        private var addOSLogger = false
        private var addConsoleLogger = false
        private var fileLoggerConfig: FileLoggerConfig?
        private var osFormatter: DDLogFormatter?
        private var consoleFormatter: DDLogFormatter?

        public init() {}

        // MARK: - OS Logger

        /// Adds `DDOSLogger` for Apple's unified logging system (Console.app / Instruments).
        ///
        /// - Parameter formatter: Optional formatter. If nil, uses CocoaLumberjack's default.
        @discardableResult
        public func withOSLogger(formatter: DDLogFormatter? = nil) -> Builder {
            addOSLogger = true
            osFormatter = formatter
            return self
        }

        // MARK: - File Logger

        /// Adds `DDFileLogger` for writing logs to files with automatic rolling.
        ///
        /// - Parameters:
        ///   - directory: Custom directory for log files. If nil, uses CocoaLumberjack's default
        ///     (`Library/Caches/Logs`).
        ///   - rollingFrequency: How often to roll to a new file, in seconds.
        ///     Default: 86400 (24 hours). Set to 0 to disable time-based rolling.
        ///   - maxFileSize: Maximum size of a single log file in bytes before rolling.
        ///     Default: 5 MB.
        ///   - maxNumberOfFiles: Maximum number of archived log files to keep.
        ///     Default: 7.
        ///   - formatter: Optional formatter for file output. If nil, uses CocoaLumberjack's default.
        @discardableResult
        public func withFileLogger(
            directory: String? = nil,
            rollingFrequency: TimeInterval = 60 * 60 * 24,
            maxFileSize: UInt64 = 5 * 1024 * 1024,
            maxNumberOfFiles: UInt = 7,
            formatter: DDLogFormatter? = nil
        ) -> Builder {
            fileLoggerConfig = FileLoggerConfig(
                directory: directory,
                rollingFrequency: rollingFrequency,
                maxFileSize: maxFileSize,
                maxNumberOfFiles: maxNumberOfFiles,
                formatter: formatter
            )
            return self
        }

        // MARK: - Console Logger

        /// Adds `DDTTYLogger` for Xcode console output.
        ///
        /// - Parameter formatter: Optional formatter. If nil, uses CocoaLumberjack's default.
        @discardableResult
        public func withConsoleLogger(formatter: DDLogFormatter? = nil) -> Builder {
            addConsoleLogger = true
            consoleFormatter = formatter
            return self
        }

        // MARK: - Build

        /// Builds the `CocoaLumberjackStrategy` and registers all configured loggers with `DDLog`.
        public func build() -> CocoaLumberjackStrategy {
            var fileLogger: DDFileLogger?

            if addOSLogger {
                let osLogger = DDOSLogger.sharedInstance
                if let formatter = osFormatter {
                    osLogger.logFormatter = formatter
                }
                DDLog.add(osLogger)
            }

            if let config = fileLoggerConfig {
                let logFileManager: DDLogFileManagerDefault
                if let directory = config.directory {
                    logFileManager = DDLogFileManagerDefault(logsDirectory: directory)
                } else {
                    logFileManager = DDLogFileManagerDefault()
                }
                logFileManager.maximumNumberOfLogFiles = config.maxNumberOfFiles

                let ddFileLogger = DDFileLogger(logFileManager: logFileManager)
                ddFileLogger.rollingFrequency = config.rollingFrequency
                ddFileLogger.maximumFileSize = config.maxFileSize
                ddFileLogger.logFormatter = config.formatter

                DDLog.add(ddFileLogger)
                fileLogger = ddFileLogger
            }

            if addConsoleLogger {
                if let ttyLogger = DDTTYLogger.sharedInstance {
                    if let formatter = consoleFormatter {
                        ttyLogger.logFormatter = formatter
                    }
                    DDLog.add(ttyLogger)
                }
            }

            return CocoaLumberjackStrategy(fileLogger: fileLogger)
        }
    }
}

// MARK: - Internal Types

private struct FileLoggerConfig {
    let directory: String?
    let rollingFrequency: TimeInterval
    let maxFileSize: UInt64
    let maxNumberOfFiles: UInt
    let formatter: DDLogFormatter?
}
