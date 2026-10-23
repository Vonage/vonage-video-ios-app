//
//  Created by Vonage on 18/10/26.
//

import Foundation
import VERADomain

@MainActor
public protocol DownloadTranscriptionUseCase {
    func callAsFunction(_ archive: Archive) async throws -> ArchiveTranscript
}

/// Downloads the transcript zip of a transcription archive so it can be shared or saved.
public final class DefaultDownloadTranscriptionUseCase: DownloadTranscriptionUseCase {

    public enum Error: Swift.Error {
        case missingURL
    }

    private let fileDownloader: ArchiveFileDownloader

    public init(fileDownloader: ArchiveFileDownloader) {
        self.fileDownloader = fileDownloader
    }

    public func callAsFunction(_ archive: Archive) async throws -> ArchiveTranscript {
        guard let url = archive.downloadURL else {
            throw Error.missingURL
        }
        let fileURL = try await fileDownloader.download(
            from: url,
            fileName: "transcription-\(archive.id.uuidString.lowercased()).zip")
        return ArchiveTranscript(id: archive.id, fileURL: fileURL)
    }
}
