//
//  Created by Vonage on 18/10/26.
//

import Foundation
import Testing
import VERAArchiving
import VERADomain

@MainActor
@Suite("Download transcription use case tests")
struct DownloadTranscriptionUseCaseTests {

    @Test("Downloads the transcript zip, not the parent archive media")
    func downloadsTranscriptURL() async throws {
        let downloader = SpyArchiveFileDownloader()
        let transcriptURL = URL(string: "https://example.com/transcript.zip")!
        let archive = makeArchive(
            url: URL(string: "https://example.com/audio.zip"),
            transcription: ArchiveTranscription(status: .available, url: transcriptURL))
        let sut = DefaultDownloadTranscriptionUseCase(fileDownloader: downloader)

        let transcript = try await sut(archive)

        #expect(downloader.requestedURLs == [transcriptURL])
        #expect(transcript.id == archive.id)
        #expect(transcript.fileURL == downloader.fileURL)
    }

    @Test("Names the local copy after the archive")
    func namesFileAfterArchive() async throws {
        let downloader = SpyArchiveFileDownloader()
        let archive = makeArchive(
            transcription: ArchiveTranscription(
                status: .available, url: URL(string: "https://example.com/transcript.zip")))
        let sut = DefaultDownloadTranscriptionUseCase(fileDownloader: downloader)

        _ = try await sut(archive)

        #expect(downloader.requestedFileNames == ["transcription-\(archive.id.uuidString.lowercased()).zip"])
    }

    @Test("Throws when the transcript has no URL")
    func throwsWhenTranscriptURLIsMissing() async {
        let downloader = SpyArchiveFileDownloader()
        let archive = makeArchive(
            url: URL(string: "https://example.com/audio.zip"),
            transcription: ArchiveTranscription(status: .started, url: nil))
        let sut = DefaultDownloadTranscriptionUseCase(fileDownloader: downloader)

        await #expect(throws: DefaultDownloadTranscriptionUseCase.Error.self) {
            try await sut(archive)
        }
        #expect(downloader.requestedURLs.isEmpty)
    }

    @Test("Propagates download failures")
    func propagatesDownloadFailures() async {
        let downloader = SpyArchiveFileDownloader()
        downloader.error = URLError(.notConnectedToInternet)
        let archive = makeArchive(
            transcription: ArchiveTranscription(
                status: .available, url: URL(string: "https://example.com/transcript.zip")))
        let sut = DefaultDownloadTranscriptionUseCase(fileDownloader: downloader)

        await #expect(throws: URLError.self) {
            try await sut(archive)
        }
    }

    // MARK: - Test Helpers

    private func makeArchive(
        url: URL? = nil,
        transcription: ArchiveTranscription?
    ) -> Archive {
        Archive(
            id: UUID(),
            name: "transcription",
            createdAt: Date(),
            status: .uploaded,
            url: url,
            size: 0,
            duration: 0,
            kind: .transcription,
            transcription: transcription)
    }
}

/// The lock protects the recorded requests; downloads run off the test's actor.
private final class SpyArchiveFileDownloader: ArchiveFileDownloader, @unchecked Sendable {
    private let lock = NSLock()
    private var _requestedURLs: [URL] = []
    private var _requestedFileNames: [String] = []
    private var _error: Error?
    let fileURL = URL(fileURLWithPath: "/tmp/transcript.zip")

    var requestedURLs: [URL] { lock.withLock { _requestedURLs } }
    var requestedFileNames: [String] { lock.withLock { _requestedFileNames } }
    var error: Error? {
        get { lock.withLock { _error } }
        set { lock.withLock { _error = newValue } }
    }

    func download(from url: URL, fileName: String) async throws -> URL {
        let error = lock.withLock {
            _requestedURLs.append(url)
            _requestedFileNames.append(fileName)
            return _error
        }
        if let error { throw error }
        return fileURL
    }
}
