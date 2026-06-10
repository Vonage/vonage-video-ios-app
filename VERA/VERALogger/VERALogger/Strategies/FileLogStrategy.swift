//
//  Created by Vonage on 8/4/26.
//

import Foundation

/// A logging strategy that writes log events to one or more files with
/// configurable rotation behaviour.
///
/// **Rotation policies:**
/// - ``RotationPolicy/truncate``: single file; content is truncated when the
///   file size exceeds the maximum. Simple but loses old logs.
/// - ``RotationPolicy/rolling(maxFileCount:)``: the current file is archived
///   with a timestamp and a new file is started. Older archives are pruned
///   when the total file count exceeds `maxFileCount`. Old logs are preserved.
///
/// Thread-safe: uses `NSLock` to serialize file I/O.
///
/// Use ``Builder`` for convenient construction:
/// ```swift
/// let strategy = FileLogStrategy.Builder(fileURL: logsDir.appending(component: "app.log"))
///     .maxFileSize(10 * 1024 * 1024)
///     .rotationPolicy(.rolling(maxFileCount: 5))
///     .build()
/// ```
public final class FileLogStrategy: LoggerStrategy, @unchecked Sendable {

    // MARK: - Types

    /// Defines what happens when the active log file exceeds ``maxFileSize``.
    public enum RotationPolicy: Sendable {
        /// Truncates the current file (existing content is lost).
        case truncate

        /// Archives the current file and creates a fresh one.
        /// Keeps at most `maxFileCount` files (current + archives).
        case rolling(maxFileCount: Int)
    }

    // MARK: - Defaults

    /// Default max file size: 5 MB.
    public static let defaultMaxFileSize: UInt64 = 5 * 1024 * 1024

    /// Default timestamp format for log lines.
    public static let defaultDateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

    /// Default minimum log level.
    public static let defaultMinLevel: LogLevel = .verbose

    /// Default rotation policy.
    public static let defaultRotationPolicy: RotationPolicy = .truncate

    static let archiveSuffix = ".log"
    static let archiveDateFormat = "yyyyMMdd-HHmmssSSS"

    // MARK: - Properties

    private let fileURL: URL
    private let logsDirectory: URL
    private let maxFileSize: UInt64
    private let rotationPolicy: RotationPolicy
    private let minLevel: LogLevel
    private let dateFormatter: DateFormatter
    private let fileNameDateFormatter: DateFormatter
    private let fileManager: FileManager
    private let lock = NSLock()
    private let archivePrefix: String

    // MARK: - Initialisation

    /// Creates a file logging strategy with all dependencies provided explicitly.
    ///
    /// Prefer using ``Builder`` for convenient construction with sensible defaults.
    ///
    /// - Parameters:
    ///   - fileURL: URL of the active log file.
    ///   - logsDirectory: Directory containing log files.
    ///   - archivePrefix: Prefix for archive file names (e.g. `"sdk-log-"`).
    ///   - maxFileSize: Maximum file size in bytes before rotation.
    ///   - rotationPolicy: How to handle a full file.
    ///   - minLevel: Minimum log level written to file.
    ///   - dateFormatter: Formatter for log line timestamps.
    ///   - fileNameDateFormatter: Formatter for archive file name timestamps.
    ///   - fileManager: File manager instance for file I/O.
    public init(
        fileURL: URL,
        logsDirectory: URL,
        archivePrefix: String,
        maxFileSize: UInt64,
        rotationPolicy: RotationPolicy,
        minLevel: LogLevel,
        dateFormatter: DateFormatter,
        fileNameDateFormatter: DateFormatter,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.logsDirectory = logsDirectory
        self.archivePrefix = archivePrefix
        self.maxFileSize = maxFileSize
        self.rotationPolicy = rotationPolicy
        self.minLevel = minLevel
        self.dateFormatter = dateFormatter
        self.fileNameDateFormatter = fileNameDateFormatter
        self.fileManager = fileManager
    }

    // MARK: - Builder

    /// Fluent builder for creating ``FileLogStrategy`` instances with sensible defaults.
    ///
    /// ```swift
    /// let strategy = FileLogStrategy.Builder(fileURL: logFile)
    ///     .archivePrefix("sdk-log-")
    ///     .rotationPolicy(.rolling(maxFileCount: 5))
    ///     .build()
    /// ```
    public final class Builder {
        private let fileURL: URL
        private var _logsDirectory: URL?
        private var _archivePrefix: String?
        private var _maxFileSize: UInt64 = FileLogStrategy.defaultMaxFileSize
        private var _rotationPolicy: RotationPolicy = FileLogStrategy.defaultRotationPolicy
        private var _minLevel: LogLevel = FileLogStrategy.defaultMinLevel
        private var _dateFormat: String = FileLogStrategy.defaultDateFormat
        private var _fileManager: FileManager = .default

        /// Creates a builder for the given log file URL.
        ///
        /// - Parameter fileURL: URL of the active log file.
        public init(fileURL: URL) {
            self.fileURL = fileURL
        }

        /// Sets the directory containing log files. Defaults to the parent directory of `fileURL`.
        @discardableResult
        public func logsDirectory(_ value: URL) -> Builder {
            _logsDirectory = value
            return self
        }

        /// Sets the archive file name prefix. Defaults to a value derived from the file name
        /// (e.g. `"sdk-log-current.log"` → `"sdk-log-"`).
        @discardableResult
        public func archivePrefix(_ value: String) -> Builder {
            _archivePrefix = value
            return self
        }

        /// Sets the maximum file size before rotation. Defaults to 5 MB.
        @discardableResult
        public func maxFileSize(_ value: UInt64) -> Builder {
            _maxFileSize = value
            return self
        }

        /// Sets the rotation policy. Defaults to `.truncate`.
        @discardableResult
        public func rotationPolicy(_ value: RotationPolicy) -> Builder {
            _rotationPolicy = value
            return self
        }

        /// Sets the minimum log level. Defaults to `.verbose`.
        @discardableResult
        public func minLevel(_ value: LogLevel) -> Builder {
            _minLevel = value
            return self
        }

        /// Sets the date format for log line timestamps. Defaults to `"yyyy-MM-dd HH:mm:ss.SSS"`.
        @discardableResult
        public func dateFormat(_ value: String) -> Builder {
            _dateFormat = value
            return self
        }

        /// Sets the file manager instance. Defaults to `.default`.
        @discardableResult
        public func fileManager(_ value: FileManager) -> Builder {
            _fileManager = value
            return self
        }

        /// Builds the ``FileLogStrategy`` instance.
        public func build() -> FileLogStrategy {
            let logsDirectory = _logsDirectory ?? fileURL.deletingLastPathComponent()

            let archivePrefix: String
            if let explicit = _archivePrefix {
                archivePrefix = explicit
            } else {
                let baseName = fileURL.deletingPathExtension().lastPathComponent
                let nameParts = baseName.components(separatedBy: "-")
                if nameParts.count >= 2 {
                    archivePrefix = nameParts.dropLast().joined(separator: "-") + "-"
                } else {
                    archivePrefix = baseName + "-"
                }
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = _dateFormat
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")

            let fileNameDateFormatter = DateFormatter()
            fileNameDateFormatter.dateFormat = FileLogStrategy.archiveDateFormat
            fileNameDateFormatter.locale = Locale(identifier: "en_US_POSIX")

            return FileLogStrategy(
                fileURL: fileURL,
                logsDirectory: logsDirectory,
                archivePrefix: archivePrefix,
                maxFileSize: _maxFileSize,
                rotationPolicy: _rotationPolicy,
                minLevel: _minLevel,
                dateFormatter: dateFormatter,
                fileNameDateFormatter: fileNameDateFormatter,
                fileManager: _fileManager
            )
        }
    }

    // MARK: - LoggerStrategy

    public func shouldLog(_ event: LogEvent) -> Bool {
        event.level >= minLevel
    }

    public func log(_ event: LogEvent) {
        guard shouldLog(event) else { return }
        let line = formatEvent(event) + "\n"
        writeData(line)
    }

    // MARK: - Raw Writing

    /// Writes raw text directly to the log file without level filtering or formatting.
    ///
    /// Useful for capturing console output verbatim (e.g. stderr redirection).
    public func writeRaw(_ text: String) {
        writeData(text)
    }

    // MARK: - File Management

    /// Returns the active log file URL.
    public func currentLogFileURL() -> URL {
        fileURL
    }

    /// Returns all managed log files sorted by modification date, newest first.
    ///
    /// In `.truncate` mode this returns at most a single file.
    public func allLogFileURLs() -> [URL] {
        lock.lock()
        defer { lock.unlock() }

        switch rotationPolicy {
        case .truncate:
            if fileManager.fileExists(atPath: fileURL.path) {
                return [fileURL]
            }
            return []

        case .rolling:
            return managedLogFileURLs(sortedNewestFirst: true)
        }
    }

    /// Deletes all managed log files.
    public func deleteAllLogFiles() {
        lock.lock()
        defer { lock.unlock() }

        switch rotationPolicy {
        case .truncate:
            try? fileManager.removeItem(at: fileURL)

        case .rolling:
            for url in managedLogFileURLs(sortedNewestFirst: false) {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    // MARK: - Formatting

    private func formattedTimestamp(_ timestamp: Date) -> String {
        dateFormatter.string(from: timestamp)
    }

    /// Formats a log event into a human-readable log line.
    internal func formatEvent(_ event: LogEvent) -> String {
        let time = formattedTimestamp(event.timestamp)
        var line = "\(time) [\(event.thread)] [\(event.level)] \(event.tag): \(event.message)"
        if let error = event.error {
            line += "\n\(error)"
        }
        return line
    }

    // MARK: - File Operations

    private func writeData(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        lock.lock()
        defer { lock.unlock() }

        do {
            try ensureFileExists()
            rotateIfNeeded(appendingByteCount: UInt64(data.count))

            let handle = try FileHandle(forWritingTo: fileURL)
            defer { try? handle.close() }
            _ = try handle.seekToEnd()
            handle.write(data)
        } catch {
            // Silently ignore — logging should never crash the app.
        }
    }

    private func ensureFileExists() throws {
        if !fileManager.fileExists(atPath: logsDirectory.path) {
            try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        }
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: nil)
        }
    }

    private func rotateIfNeeded(appendingByteCount: UInt64) {
        guard
            let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
            let fileSize = attributes[.size] as? UInt64
        else {
            return
        }

        let (updatedSize, didOverflow) = fileSize.addingReportingOverflow(appendingByteCount)
        guard didOverflow || updatedSize > maxFileSize else { return }

        switch rotationPolicy {
        case .truncate:
            try? Data().write(to: fileURL)

        case .rolling:
            let archiveURL = logsDirectory.appendingPathComponent(archiveFileName(for: Date()))
            do {
                if fileManager.fileExists(atPath: archiveURL.path) {
                    try fileManager.removeItem(at: archiveURL)
                }
                try fileManager.moveItem(at: fileURL, to: archiveURL)
                fileManager.createFile(atPath: fileURL.path, contents: nil)
                pruneArchivedFiles()
            } catch {
                // Silently ignore — logging should never crash the app.
            }
        }
    }

    // MARK: - Rolling helpers

    private func pruneArchivedFiles() {
        guard case .rolling(let maxFileCount) = rotationPolicy else { return }
        let clamped = max(1, maxFileCount)
        let files = managedLogFileURLs(sortedNewestFirst: false)
        let excessCount = files.count - clamped
        guard excessCount > 0 else { return }

        let archiveCandidates = files.filter { $0.lastPathComponent != fileURL.lastPathComponent }
        for url in archiveCandidates.prefix(excessCount) {
            try? fileManager.removeItem(at: url)
        }
    }

    private func managedLogFileURLs(sortedNewestFirst: Bool) -> [URL] {
        guard
            let urls = try? fileManager.contentsOfDirectory(
                at: logsDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        else {
            return []
        }

        return
            urls
            .filter(isManagedLogFile)
            .sorted { lhs, rhs in
                let leftDate = modificationDate(for: lhs)
                let rightDate = modificationDate(for: rhs)

                if leftDate == rightDate {
                    return lhs.lastPathComponent < rhs.lastPathComponent
                }

                return sortedNewestFirst ? leftDate > rightDate : leftDate < rightDate
            }
    }

    private func modificationDate(for url: URL) -> Date {
        let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return resourceValues?.contentModificationDate ?? .distantPast
    }

    private func isManagedLogFile(_ url: URL) -> Bool {
        let fileName = url.lastPathComponent
        if fileName == fileURL.lastPathComponent {
            return true
        }

        guard
            fileName.hasPrefix(archivePrefix),
            fileName.hasSuffix(Self.archiveSuffix)
        else {
            return false
        }

        let timestamp = String(
            fileName
                .dropFirst(archivePrefix.count)
                .dropLast(Self.archiveSuffix.count)
        )

        return isTimestampFileName(timestamp)
    }

    private func isTimestampFileName(_ value: String) -> Bool {
        guard value.count == 18 else { return false }
        for (index, character) in value.enumerated() {
            if index == 8 {
                guard character == "-" else { return false }
            } else if !character.isNumber {
                return false
            }
        }
        return true
    }
    private func archiveFileName(for date: Date) -> String {
        "\(archivePrefix)\(fileNameDateFormatter.string(from: date))\(Self.archiveSuffix)"
    }
}
