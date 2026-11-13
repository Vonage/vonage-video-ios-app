//
//  Created by Vonage on 26/10/26.
//

import Foundation

/// Appends raw log output to a bounded, rotating set of files.
///
/// A logging session owns at most ``RotatingLogFileSet/defaultMaxFileCount`` files named
/// `<timestamp>_log.1` … `<timestamp>_log.5`. Every file of a set shares the timestamp of
/// the session that created it. Once the current file reaches `maxFileSize` writing moves
/// on to the next index; after the last index the oldest file is emptied and reused, so the
/// set never grows beyond `maxFileCount` files.
///
/// Relaunching the app adopts the existing set and keeps appending to the file that was
/// written last, so logs survive a restart as long as the configuration is unchanged.
///
/// All file access happens inside the actor, so callers never block the main thread and no
/// locking is required.
///
/// ```swift
/// let files = RotatingLogFileSet(directory: RotatingLogFileSet.defaultDirectory)
/// await files.write(Data("hello\n".utf8))
/// let urls = await files.fileURLs()
/// ```
public actor RotatingLogFileSet {

    /// Default maximum size of a single log file: 5 MB.
    public static let defaultMaxFileSize: UInt64 = 5 * 1024 * 1024

    /// Default number of files a rotation set is allowed to use.
    public static let defaultMaxFileCount = 5

    /// Separates the session timestamp from the file index in a managed file name.
    static let fileNameSeparator = "_log."

    /// Directory holding the managed log files: `<Library>/Logs/Vonage`.
    ///
    /// `Library/Logs` is the location Apple reserves for application logs: unlike `Caches`
    /// it is not purged by the system, and it stays inside the app container so the share
    /// sheet can read the files back.
    public static var defaultDirectory: URL {
        let library =
            FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return
            library
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("Vonage", isDirectory: true)
    }

    private let directory: URL
    private let maxFileSize: UInt64
    private let maxFileCount: Int

    /// Timestamp shared by the files of the active set. `nil` until the set is prepared.
    private var sessionTimestamp: String?

    /// Index (1-based) of the file currently being appended to.
    private var currentIndex = 1

    /// Size in bytes of the file currently being appended to.
    private var currentFileSize: UInt64 = 0

    /// Creates a rotating log file set.
    ///
    /// Creating the set touches no files; the directory and the log files are created the
    /// first time something is written.
    ///
    /// - Parameters:
    ///   - directory: Directory that holds the managed log files.
    ///   - maxFileSize: Maximum size in bytes of a single file. Defaults to 5 MB.
    ///   - maxFileCount: Maximum number of files in the set. Defaults to 5.
    public init(
        directory: URL,
        maxFileSize: UInt64 = RotatingLogFileSet.defaultMaxFileSize,
        maxFileCount: Int = RotatingLogFileSet.defaultMaxFileCount
    ) {
        self.directory = directory
        self.maxFileSize = maxFileSize
        self.maxFileCount = max(1, maxFileCount)
    }

    // MARK: - Writing

    /// Appends the given bytes to the active log file, rotating first when it is full.
    ///
    /// Failures are swallowed: logging must never bring the app down.
    ///
    /// - Parameter data: Raw bytes to append.
    public func write(_ data: Data) {
        guard !data.isEmpty, maxFileSize > 0 else { return }
        do {
            try prepareIfNeeded()

            var offset = 0
            while offset < data.count {
                if currentFileSize >= maxFileSize {
                    try rotate()
                }

                let availableSize = maxFileSize - currentFileSize
                let chunkSize = Int(min(availableSize, UInt64(data.count - offset)))
                let endOffset = offset + chunkSize
                let chunk = data.subdata(in: offset..<endOffset)
                do {
                    let handle = try FileHandle(forWritingTo: currentFileURL())
                    defer { try? handle.close() }
                    try handle.seekToEnd()
                    try handle.write(contentsOf: chunk)
                }
                currentFileSize += UInt64(chunkSize)
                offset = endOffset
            }
        } catch {
            // Intentionally ignored — logging should never crash the app.
        }
    }

    // MARK: - Reading and clean-up

    /// URLs of the managed log files that currently exist, oldest set and index first.
    public func fileURLs() -> [URL] {
        managedFiles()
            .sorted { lhs, rhs in
                lhs.timestamp == rhs.timestamp ? lhs.index < rhs.index : lhs.timestamp < rhs.timestamp
            }
            .map(\.url)
    }

    /// Deletes every managed log file and starts a new set on the next write.
    public func clear() {
        for file in managedFiles() {
            try? FileManager.default.removeItem(at: file.url)
        }
        sessionTimestamp = nil
        currentIndex = 1
        currentFileSize = 0
    }

    // MARK: - Rotation

    /// Resolves the set to append to, reusing the one left behind by a previous launch.
    private func prepareIfNeeded() throws {
        guard sessionTimestamp == nil else { return }

        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        let existing = managedFiles()
        if let latestTimestamp = existing.map(\.timestamp).max() {
            sessionTimestamp = latestTimestamp
            // The highest index is not necessarily the newest file: once the set wraps
            // around, the lowest index is reused. Modification dates give the real order.
            let candidates = existing.filter { $0.timestamp == latestTimestamp }
            currentIndex =
                candidates
                .max {
                    (modificationDate(of: $0.url), $0.index) < (modificationDate(of: $1.url), $1.index)
                }?
                .index ?? 1
        } else {
            sessionTimestamp = Self.makeTimestamp(Date())
            currentIndex = 1
        }

        let url = currentFileURL()
        if !FileManager.default.fileExists(atPath: url.path) {
            guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
                sessionTimestamp = nil
                throw CocoaError(.fileWriteUnknown)
            }
        }
        currentFileSize = fileSize(of: url)
    }

    /// Moves to the next file of the set, emptying it so the set stays bounded.
    private func rotate() throws {
        currentIndex = currentIndex % maxFileCount + 1
        try Data().write(to: currentFileURL())
        currentFileSize = 0
    }

    // MARK: - File names

    private func currentFileURL() -> URL {
        fileURL(timestamp: sessionTimestamp ?? Self.makeTimestamp(Date()), index: currentIndex)
    }

    private func fileURL(timestamp: String, index: Int) -> URL {
        directory.appendingPathComponent("\(timestamp)\(Self.fileNameSeparator)\(index)")
    }

    /// A log file belonging to a managed set.
    private struct ManagedFile {
        let timestamp: String
        let index: Int
        let url: URL
    }

    /// Every file in the directory that follows the `<timestamp>_log.<index>` convention.
    private func managedFiles() -> [ManagedFile] {
        let contents =
            (try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            )) ?? []

        return contents.compactMap { url in
            let name = url.lastPathComponent
            guard let separator = name.range(of: Self.fileNameSeparator, options: .backwards),
                let index = Int(name[separator.upperBound...]),
                (1...maxFileCount).contains(index)
            else {
                return nil
            }
            let timestamp = String(name[name.startIndex..<separator.lowerBound])
            guard timestamp.range(of: #"^[0-9]{8}-[0-9]{6}$"#, options: .regularExpression) != nil,
                name == "\(timestamp)\(Self.fileNameSeparator)\(index)"
            else {
                return nil
            }
            return ManagedFile(timestamp: timestamp, index: index, url: url)
        }
    }

    private static func makeTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    private func fileSize(of url: URL) -> UInt64 {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.size] as? UInt64 ?? 0
    }

    private func modificationDate(of url: URL) -> Date {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.modificationDate] as? Date ?? .distantPast
    }
}
