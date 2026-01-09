//
//  Created by Vonage on 6/8/25.
//

import Foundation
import VERADomain

public actor DefaultArchiveRecordingsRepository: ArchiveRecordingsRepository {
    private let httpClient: HTTPClient
    private let fileManager: FileManager
    private let cacheDirectory: URL

    private var downloadedRecordings: [UUID: ArchiveRecording] = [:]
    private var downloadTasks: [UUID: Task<ArchiveRecording, Error>] = [:]

    public init(
        httpClient: HTTPClient,
        fileManager: FileManager = .default,
        cacheDirectory: URL? = nil
    ) {
        self.httpClient = httpClient
        self.fileManager = fileManager

        // Setup cache directory
        if let cacheDirectory = cacheDirectory {
            self.cacheDirectory = cacheDirectory
        } else {
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.cacheDirectory = documentsPath.appendingPathComponent("ArchiveRecordings")
        }

        // Ensure cache directory exists
        try? fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - ArchiveRecordingsRepository
    public func getRecording(_ archive: Archive) async throws -> ArchiveRecording {
        // Check if already cached in memory
        if let cachedRecording = downloadedRecordings[archive.id] {
            return cachedRecording
        }

        // Check if there's an ongoing download task
        if let existingTask = downloadTasks[archive.id] {
            return try await existingTask.value
        }

        // Check if file exists in local cache
        let localFileURL = localFileURL(for: archive)
        if fileManager.fileExists(atPath: localFileURL.path) {
            let recording = ArchiveRecording(url: localFileURL)
            downloadedRecordings[archive.id] = recording
            return recording
        }

        let task = Task<ArchiveRecording, Error> { [weak self] in
            guard let self = self else {
                throw ArchiveRecordingError.downloadFailed("Repository deallocated")
            }

            guard let remoteURL = archive.url else {
                throw ArchiveRecordingError.noDownloadURL
            }

            // Download file data
            let data = try await self.httpClient.get(remoteURL)

            // Save to local cache
            let fileURL = await self.localFileURL(for: archive)
            try data.write(to: fileURL)

            // Create and cache recording atomically
            let recording = ArchiveRecording(url: fileURL)
            await self.updateCacheAfterDownload(archive: archive, recording: recording)

            return recording
        }

        // Store the task immediately to prevent duplicate downloads
        downloadTasks[archive.id] = task

        return try await task.value
    }

    private func updateCacheAfterDownload(archive: Archive, recording: ArchiveRecording) {
        downloadedRecordings[archive.id] = recording
        downloadTasks.removeValue(forKey: archive.id)
    }

    private func localFileURL(for archive: Archive) -> URL {
        let filename = "\(archive.id.uuidString).mp4"
        return cacheDirectory.appendingPathComponent(filename)
    }
}

// MARK: - Errors
public enum ArchiveRecordingError: Error, LocalizedError, Equatable {
    case noDownloadURL
    case downloadFailed(String)
    case fileNotFound

    public var errorDescription: String? {
        switch self {
        case .noDownloadURL:
            return "Archive does not have a download URL"
        case .downloadFailed(let errorMessage):
            return "Failed to download recording: \(errorMessage)"
        case .fileNotFound:
            return "Recording file not found"
        }
    }

    public static func == (lhs: ArchiveRecordingError, rhs: ArchiveRecordingError) -> Bool {
        switch (lhs, rhs) {
        case (.noDownloadURL, .noDownloadURL):
            return true
        case (.fileNotFound, .fileNotFound):
            return true
        case (.downloadFailed(let lhsMessage), .downloadFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}
