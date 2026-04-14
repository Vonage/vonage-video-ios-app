//
//  Created by Vonage on 8/4/26.
//

import Foundation

/// A logger facade that provides convenience logging methods and a builder for configuration.
///
///
/// ```swift
/// let logger = VonageLogger.Builder()
///     .addStrategy(OSLogStrategy())
///     .addStrategy(DefaultLogStrategy())
///     .addStrategy(FileLogStrategy(fileURL: myLogFileURL))
///     .build()
///
/// logger.debug("MyFeature", "User logged in")
/// logger.error("MyFeature", "Something failed", error)
/// ```
public final class VonageLogger: Sendable {

    private let composite: LoggerComposite

    private init(composite: LoggerComposite) {
        self.composite = composite
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

    /// Logs an event with the given level, tag, message, and optional error.
    public func log(level: LogLevel, tag: String, message: String, error: Error? = nil) {
        let event = LogEvent(level: level, tag: tag, message: message, error: error)
        composite.log(event)
    }

    /// Logs an event synchronously. Use for critical errors where order matters.
    public func logSync(level: LogLevel, tag: String, message: String, error: Error? = nil) {
        let event = LogEvent(level: level, tag: tag, message: message, error: error)
        composite.logSync(event)
    }

    // MARK: - Builder

    /// A builder for constructing a `VonageLogger` with a custom set of strategies.
    ///
    /// ```swift
    /// let logger = VonageLogger.Builder()
    ///     .addStrategy(OSLogStrategy())
    ///     .build()
    /// ```
    public final class Builder {
        private var strategies: [any LoggerStrategy] = []

        public init() {}

        @discardableResult
        public func addStrategy(_ strategy: any LoggerStrategy) -> Builder {
            strategies.append(strategy)
            return self
        }

        public func build() -> VonageLogger {
            let composite = LoggerComposite(strategies: strategies)
            return VonageLogger(composite: composite)
        }
    }
}

// MARK: - Default Instance

/// A pre-configured logger that uses the OS log strategy.
///
/// Use this for quick access when custom configuration is not needed:
/// ```swift
/// vonageLogger.debug("App", "Application did launch")
/// ```
public let vonageLogger = VonageLogger.Builder()
    .addStrategy(OSLogStrategy())
    .build()
