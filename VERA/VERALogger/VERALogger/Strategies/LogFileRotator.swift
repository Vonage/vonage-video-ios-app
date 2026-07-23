//
//  Created by Vonage on 8/4/26.
//

import Foundation

/// Enforces log file rotation when the active file exceeds a size threshold.
///
/// Supports two policies:
/// - ``FileLogStrategy/RotationPolicy/truncate``: clears the file (old data lost).
/// - ``FileLogStrategy/RotationPolicy/rolling(maxFileCount:)``: archives the file
///   and starts a new one, pruning old archives.
///
/// Thread-safety is the caller's responsibility (``FileLogStrategy`` holds
/// a lock around all file operations).
public struct LogFileRotator: Sendable {

    private let fileURL: URL
    private let maxFileSize: UInt64
    private let rotationPolicy: FileLogStrategy.RotationPolicy
    private let archiveManager: LogFileArchiveManager
    private let fileManager: FileManager

    /// Creates a new rotator.
    ///
    /// - Parameters:
    ///   - fileURL: URL of the active log file.
    ///   - maxFileSize: Maximum file size in bytes before rotation.
    ///   - rotationPolicy: How to handle a full file.
    ///   - archiveManager: Manager for archive creation and pruning.
    ///   - fileManager: File manager instance for file attribute queries.
    public init(
        fileURL: URL,
        maxFileSize: UInt64,
        rotationPolicy: FileLogStrategy.RotationPolicy,
        archiveManager: LogFileArchiveManager,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.maxFileSize = maxFileSize
        self.rotationPolicy = rotationPolicy
        self.archiveManager = archiveManager
        self.fileManager = fileManager
    }

    /// Rotates the log file if appending `byteCount` bytes would exceed the maximum size.
    ///
    /// - Parameter byteCount: Number of bytes about to be written.
    public func rotateIfNeeded(appendingByteCount byteCount: UInt64) {
        guard
            let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
            let fileSize = attributes[.size] as? UInt64
        else {
            return
        }

        let (updatedSize, didOverflow) = fileSize.addingReportingOverflow(byteCount)
        guard didOverflow || updatedSize > maxFileSize else { return }

        switch rotationPolicy {
        case .truncate:
            try? Data().write(to: fileURL)

        case .rolling(let maxFileCount):
            do {
                try archiveManager.archiveFile(at: fileURL)
                archiveManager.pruneArchivedFiles(maxFileCount: maxFileCount, activeFileURL: fileURL)
            } catch {
                // Silently ignore — logging should never crash the app.
            }
        }
    }
}
