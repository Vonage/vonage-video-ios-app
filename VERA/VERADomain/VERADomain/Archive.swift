//
//  Created by Vonage on 4/8/25.
//

import Foundation

/// Status of an archive, or of the transcription attached to it, as reported by `searchArchives`.
public enum ArchiveStatus: String, Sendable, CaseIterable {
    case requested, started, paused, stopped, uploaded, available, expired, failed, deleted

    /// Maps a raw status to its case. Unknown statuses are treated as `.failed`.
    public init(value: String) {
        self = ArchiveStatus(rawValue: value) ?? .failed
    }

    /// Whether the file is still being produced and may become available later.
    public var isPending: Bool {
        switch self {
        case .requested, .started, .paused, .stopped: true
        case .uploaded, .available, .expired, .failed, .deleted: false
        }
    }
}

/// The post-call transcript produced from a transcription archive.
public struct ArchiveTranscription: Equatable, Sendable {
    public let status: ArchiveStatus
    public let url: URL?

    public init(status: ArchiveStatus, url: URL?) {
        self.status = status
        self.url = url
    }
}

public struct Archive: Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let createdAt: Date
    public let status: ArchiveStatus
    public let url: URL?
    public let size: Int
    public let duration: Int
    public let kind: ArchiveKind
    public let transcription: ArchiveTranscription?

    public init(
        id: UUID,
        name: String,
        createdAt: Date,
        status: ArchiveStatus,
        url: URL?,
        size: Int,
        duration: Int,
        kind: ArchiveKind = .recording,
        transcription: ArchiveTranscription? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.status = status
        self.url = url
        self.size = size
        self.duration = duration
        self.kind = kind
        self.transcription = transcription
    }

    /// URL of the file the user downloads once it is available:
    /// the transcript zip for transcriptions, the media otherwise.
    public var downloadURL: URL? {
        switch kind {
        case .recording: status == .available ? url : nil
        case .transcription: transcription?.status == .available ? transcription?.url : nil
        }
    }

    /// Whether the archive or its transcript is still being produced.
    ///
    /// A transcription keeps processing after its parent archive is uploaded or available.
    public var isPending: Bool {
        status.isPending || (transcription?.status.isPending ?? false)
    }
}
