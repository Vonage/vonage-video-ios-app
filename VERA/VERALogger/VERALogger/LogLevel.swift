//
//  Created by Vonage on 8/4/26.
//

import Foundation

/// Severity levels for log events, ordered from least to most severe.
///
/// Conforms to `Comparable` so strategies can filter by minimum level.
public enum LogLevel: Int, Sendable, Comparable, CaseIterable, CustomStringConvertible {
    case verbose = 0
    case debug = 1
    case info = 2
    case warn = 3
    case error = 4

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
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
}
