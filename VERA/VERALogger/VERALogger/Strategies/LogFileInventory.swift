//
//  Created by Vonage on 8/4/26.
//

import Foundation

/// Manages the inventory of log files in a directory, identifying which
/// files belong to the current logging session based on naming conventions.
///
/// Thread-safety is the caller's responsibility (``FileLogStrategy`` holds
/// a lock around all file operations).
public struct LogFileInventory: Sendable {

    private let fileURL: URL
    private let logsDirectory: URL
    private let archivePrefix: String
    private let archiveSuffix: String
    private let fileManager: FileManager

    /// Creates a new log file inventory.
    ///
    /// - Parameters:
    ///   - fileURL: URL of the active (current) log file.
    ///   - logsDirectory: Directory containing log files.
    ///   - archivePrefix: Prefix for archive file names (e.g. `"sdk-log-"`).
    ///   - archiveSuffix: Suffix for archive file names (e.g. `".log"`).
    ///   - fileManager: File manager instance for directory listing.
    public init(
        fileURL: URL,
        logsDirectory: URL,
        archivePrefix: String,
        archiveSuffix: String = ".log",
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.logsDirectory = logsDirectory
        self.archivePrefix = archivePrefix
        self.archiveSuffix = archiveSuffix
        self.fileManager = fileManager
    }

    /// Returns all managed log files sorted by modification date.
    ///
    /// Includes both the active log file and any archived files that match
    /// the naming convention.
    ///
    /// - Parameter newestFirst: Sort order. `true` returns newest files first.
    /// - Returns: Sorted array of managed log file URLs.
    public func managedLogFileURLs(sortedNewestFirst newestFirst: Bool) -> [URL] {
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
            .filter { isManagedLogFile($0) }
            .sorted { lhs, rhs in
                let leftDate = modificationDate(for: lhs)
                let rightDate = modificationDate(for: rhs)

                if leftDate == rightDate {
                    return lhs.lastPathComponent < rhs.lastPathComponent
                }

                return newestFirst ? leftDate > rightDate : leftDate < rightDate
            }
    }

    /// Whether the given URL is a managed log file (active or archived).
    public func isManagedLogFile(_ url: URL) -> Bool {
        let fileName = url.lastPathComponent
        if fileName == fileURL.lastPathComponent {
            return true
        }

        guard
            fileName.hasPrefix(archivePrefix),
            fileName.hasSuffix(archiveSuffix)
        else {
            return false
        }

        let timestamp = String(
            fileName
                .dropFirst(archivePrefix.count)
                .dropLast(archiveSuffix.count)
        )

        return isTimestampFileName(timestamp)
    }

    private func modificationDate(for url: URL) -> Date {
        let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return resourceValues?.contentModificationDate ?? .distantPast
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
}
