//
//  Created by Vonage on 8/4/26.
//

import Foundation
import os

protocol OSLoggerType: Sendable {
    func trace(_ message: String)
    func debug(_ message: String)
    func info(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
}

private struct SystemOSLogger: OSLoggerType {
    private let logger: os.Logger

    init(logger: os.Logger) {
        self.logger = logger
    }

    func trace(_ message: String) {
        logger.trace("\(message, privacy: .public)")
    }

    func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}

/// A logging strategy that uses Apple's native `os.Logger`.
///
/// Maps `LogLevel` to the appropriate `OSLogType` for optimal integration
/// with Console.app and Instruments.
public struct OSLogStrategy: LoggerStrategy, Sendable {

    private let logger: any OSLoggerType

    /// Creates an OS log strategy.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem identifier (defaults to the app's bundle ID).
    ///   - category: The log category (defaults to "VERALogger").
    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.vonage.VERA",
        category: String = "VERALogger"
    ) {
        let logger = os.Logger(subsystem: subsystem, category: category)
        self.logger = SystemOSLogger(logger: logger)
    }

    internal init(logger: any OSLoggerType) {
        self.logger = logger
    }

    public func log(_ event: LogEvent) {
        let message = formatMessage(event)
        switch event.level {
        case .verbose:
            logger.trace(message)
        case .debug:
            logger.debug(message)
        case .info:
            logger.info(message)
        case .warn:
            logger.warning(message)
        case .error:
            logger.error(message)
        }
    }

    private func formatMessage(_ event: LogEvent) -> String {
        var msg = "[\(event.tag)] \(event.message)"
        if let error = event.error {
            msg += "\n\(error)"
        }
        return msg
    }
}
