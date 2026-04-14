//
//  Created by Vonage on 8/4/26.
//

import Foundation
import os

/// A logging strategy that uses Apple's native `os.Logger`.
///
/// Maps `LogLevel` to the appropriate `OSLogType` for optimal integration
/// with Console.app and Instruments.
public struct OSLogStrategy: LoggerStrategy, Sendable {

    private let logger: os.Logger

    /// Creates an OS log strategy.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem identifier (defaults to the app's bundle ID).
    ///   - category: The log category (defaults to "VERALogger").
    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.vonage.VERA",
        category: String = "VERALogger"
    ) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }

    public func log(_ event: LogEvent) {
        let message = formatMessage(event)
        switch event.level {
        case .verbose:
            logger.trace("\(message, privacy: .public)")
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .warn:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
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
