//
//  Created by Vonage on 8/4/26.
//

import Foundation

/// Manages archive file creation and pruning for rolling log rotation.
///
/// Thread-safety is the caller's responsibility (``FileLogStrategy`` holds
/// a lock around all file operations).
public struct LogFileArchiveManager: Sendable {

    private let logsDirectory: URL
    private let archivePrefix: String
    private let archiveSuffix: String
    private let fileNameDateFormatter: DateFormatter
    private let fileManager: FileManager
    private let inventory: LogFileInventory

    /// Creates a new archive manager.
    ///
    /// - Parameters:
    ///   - logsDirectory: Directory containing log files.
    ///   - archivePrefix: Prefix for archive file names.
    ///   - archiveSuffix: Suffix for archive file names.
    ///   - fileNameDateFormatter: Formatter for archive file name timestamps.
    ///   - fileManager: File manager instance for file I/O.
    ///   - inventory: Log file inventory for listing managed files.
    public init(
        logsDirectory: URL,
        archivePrefix: String,
        archiveSuffix: String = ".log",
        fileNameDateFormatter: DateFormatter,
        fileManager: FileManager = .default,
        inventory: LogFileInventory
    ) {
        self.logsDirectory = logsDirectory
        self.archivePrefix = archivePrefix
        self.archiveSuffix = archiveSuffix
        self.fileNameDateFormatter = fileNameDateFormatter
        self.fileManager = fileManager
        self.inventory = inventory
    }

    /// Generates an archive file name for the given date.
    ///
    /// - Parameter date: The date to use in the archive file name.
    /// - Returns: The archive file name string.
    public func archiveFileName(for date: Date) -> String {
        "\(archivePrefix)\(fileNameDateFormatter.string(from: date))\(archiveSuffix)"
    }

    /// Archives the active log file by moving it to a timestamped name.
    ///
    /// - Parameters:
    ///   - fileURL: The active log file to archive.
    ///   - date: The date to use for the archive name. Defaults to now.
    /// - Throws: File system errors if the move fails.
    public func archiveFile(at fileURL: URL, date: Date = Date()) throws {
        let archiveURL = logsDirectory.appendingPathComponent(archiveFileName(for: date))
        if fileManager.fileExists(atPath: archiveURL.path) {
            try fileManager.removeItem(at: archiveURL)
        }
        try fileManager.moveItem(at: fileURL, to: archiveURL)
        fileManager.createFile(atPath: fileURL.path, contents: nil)
    }

    /// Removes the oldest archive files to stay within the maximum file count.
    ///
    /// - Parameters:
    ///   - maxFileCount: Maximum number of total files (current + archives) to keep.
    ///   - activeFileURL: The active log file URL (excluded from deletion).
    public func pruneArchivedFiles(maxFileCount: Int, activeFileURL: URL) {
        let clamped = max(1, maxFileCount)
        let files = inventory.managedLogFileURLs(sortedNewestFirst: false)
        let excessCount = files.count - clamped
        guard excessCount > 0 else { return }

        let archiveCandidates = files.filter { $0.lastPathComponent != activeFileURL.lastPathComponent }
        for url in archiveCandidates.prefix(excessCount) {
            try? fileManager.removeItem(at: url)
        }
    }
}
