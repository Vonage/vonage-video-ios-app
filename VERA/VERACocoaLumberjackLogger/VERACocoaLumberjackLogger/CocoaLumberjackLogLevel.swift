//
//  Created by Vonage on 8/4/26.
//

import CocoaLumberjackSwift
import Foundation

/// Severity levels for log events, ordered from least to most severe.
///
/// Conforms to `Comparable` so callers can filter by minimum level.
public enum CocoaLumberjackLogLevel: Int, Sendable, Comparable, CaseIterable, CustomStringConvertible {
    case verbose = 0
    case debug = 1
    case info = 2
    case warn = 3
    case error = 4

    public static func < (lhs: CocoaLumberjackLogLevel, rhs: CocoaLumberjackLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warn: return "WARN"
        case .error: return "ERROR"
        }
    }

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
