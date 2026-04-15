//
//  Created by Vonage on 8/4/26.
//

import Foundation

/// A logging strategy that writes log events to a file with automatic rotation.
///
///
/// Thread-safe: uses `NSLock` to serialize file I/O.
///
/// ```swift
/// let fileStrategy = FileLogStrategy(
///     fileURL: logsDirectory.appendingPathComponent("app.log")
/// )
/// ```
public final class FileLogStrategy: LoggerStrategy, @unchecked Sendable {

    /// Default max file size: 5 MB.
    public static let defaultMaxFileSize: UInt64 = 5 * 1024 * 1024

    /// Default timestamp format.
    public static let defaultDateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

    private let fileURL: URL
    private let maxFileSize: UInt64
    private let dateFormatter: DateFormatter
    private let lock = NSLock()

    /// Creates a file logging strategy.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the log file.
    ///   - maxFileSize: Maximum file size in bytes before rotation. Defaults to 5 MB.
    ///   - dateFormat: The date format string for timestamps.
    public init(
        fileURL: URL,
        maxFileSize: UInt64 = FileLogStrategy.defaultMaxFileSize,
        dateFormat: String = FileLogStrategy.defaultDateFormat
    ) {
        self.fileURL = fileURL
        self.maxFileSize = maxFileSize
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter = formatter
    }

    public func log(_ event: LogEvent) {
        writeToFile(event)
    }

    // MARK: - Formatting

    /// Formats a log event into a human-readable log line.
    ///
    /// Visible for testing.
    internal func formatEvent(_ event: LogEvent) -> String {
        let time = dateFormatter.string(from: event.timestamp)
        var line = "\(time) [\(event.thread)] [\(event.level)] \(event.tag): \(event.message)"
        if let error = event.error {
            line += "\n\(error)"
        }
        return line
    }

    // MARK: - File Operations

    private func writeToFile(_ event: LogEvent) {
        lock.lock()
        defer { lock.unlock() }

        let line = formatEvent(event) + "\n"
        guard let data = line.data(using: .utf8) else { return }

        do {
            try ensureFileExists()
            try rotateIfNeeded()

            let handle = try FileHandle(forWritingTo: fileURL)
            defer { try? handle.close() }
            _ = try handle.seekToEnd()
            handle.write(data)
        } catch {
            // Silently ignore — logging should never crash the app.
        }
    }

    private func ensureFileExists() throws {
        let directory = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
    }

    private func rotateIfNeeded() throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attributes[.size] as? UInt64 ?? 0
        if fileSize > maxFileSize {
            try Data().write(to: fileURL)
        }
    }
}
