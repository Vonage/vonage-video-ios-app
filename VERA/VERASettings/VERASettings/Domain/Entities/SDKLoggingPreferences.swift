//
//  Created by Vonage on 21/05/2026.
//

import Foundation

/// Value type representing persisted SDK logging preferences.
///
/// This structure is stored by the Settings module and read when configuring
/// SDK logging for a session.
public struct SDKLoggingPreferences: Codable, Equatable, Sendable {
    /// Whether SDK logging is enabled.
    public let isLoggingEnabled: Bool

    /// Minimum severity level to emit when logging is enabled.
    public let logLevel: SDKLogLevel

    /// When `true`, log files should be cleared on the next app launch
    /// before SDK logging is configured. This flag is set when the user
    /// changes the logging toggle or log level and is consumed (reset to
    /// `false`) by the startup code after cleanup.
    public var pendingLogCleanup: Bool

    /// The default SDK logging preferences.
    public static var `default` = SDKLoggingPreferences()

    /// Creates a new SDK logging preferences value.
    ///
    /// - Parameters:
    ///   - isLoggingEnabled: Whether SDK logging is enabled. Defaults to `true`.
    ///   - logLevel: The configured SDK log level. Defaults to `.debug`.
    ///   - pendingLogCleanup: Whether log files should be cleared on next launch. Defaults to `false`.
    public init(
        isLoggingEnabled: Bool = true,
        logLevel: SDKLogLevel = SDKLogLevel.default,
        pendingLogCleanup: Bool = false
    ) {
        self.isLoggingEnabled = isLoggingEnabled
        self.logLevel = logLevel
        self.pendingLogCleanup = pendingLogCleanup
    }
}
