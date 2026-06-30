//
//  Created by Vonage on 21/05/2026.
//

import Foundation

/// Severity levels available for SDK logging.
///
/// The raw value matches the configured logging priority so levels can be
/// compared, persisted, and bridged to SDK-specific logging APIs.
public enum SDKLogLevel: Int, Codable, Sendable, CaseIterable, Identifiable, Comparable, CustomStringConvertible {
    /// Most detailed diagnostic output.
    case verbose = 0

    /// Debug information intended for development.
    case debug = 1

    /// General informational messages.
    case info = 2

    /// Warning messages that do not stop execution.
    case warn = 3

    /// Error messages for failed operations.
    case error = 4

    /// Unique identifier for SwiftUI lists and pickers.
    public var id: Self { self }

    /// Uppercase representation used for logging and persistence diagnostics.
    public var description: String {
        switch self {
        case .verbose: "VERBOSE"
        case .debug: "DEBUG"
        case .info: "INFO"
        case .warn: "WARN"
        case .error: "ERROR"
        }
    }

    /// Human-readable label shown in the Settings UI.
    public var displayName: String {
        switch self {
        case .verbose: "Verbose".localized
        case .debug: "Debug".localized
        case .info: "Info".localized
        case .warn: "Warn".localized
        case .error: "Error".localized
        }
    }

    public static var `default`: SDKLogLevel {
        #if DEBUG
            return .debug
        #else
            return .error
        #endif
    }

    public static func < (lhs: SDKLogLevel, rhs: SDKLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
