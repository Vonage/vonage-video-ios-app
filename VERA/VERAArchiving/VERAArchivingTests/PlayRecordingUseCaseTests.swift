//
//  Created by Vonage on 20/10/26.
//

import Foundation
import Testing
import VERAArchiving
import VERADomain

@Suite("Play recording use case tests")
struct PlayRecordingUseCaseTests {

    @Test("Opens the recording URL")
    func opensRecordingURL() async throws {
        let url = try #require(URL(string: "https://example.com/recording.mp4"))
        var opened: [URL] = []
        let sut = DefaultPlayRecordingUseCase { opened.append($0.url) }

        try await sut(makeArchive(kind: .recording, status: .available, url: url))

        #expect(opened == [url])
    }

    @Test("Opens the transcript zip, not the parent archive media")
    func opensTranscriptURL() async throws {
        let transcriptURL = try #require(URL(string: "https://example.com/transcript.zip"))
        var opened: [URL] = []
        let sut = DefaultPlayRecordingUseCase { opened.append($0.url) }

        try await sut(
            makeArchive(
                kind: .transcription,
                status: .available,
                url: URL(string: "https://example.com/audio.zip"),
                transcription: ArchiveTranscription(status: .available, url: transcriptURL)))

        #expect(opened == [transcriptURL])
    }

    @Test("Throws when the file is not available yet")
    func throwsWhenFileIsNotAvailable() async {
        let sut = DefaultPlayRecordingUseCase { _ in }

        await #expect(throws: DefaultPlayRecordingUseCase.Error.self) {
            try await sut(
                makeArchive(
                    kind: .transcription,
                    status: .available,
                    transcription: ArchiveTranscription(status: .started, url: nil)))
        }
    }

    // MARK: - Test Helpers

    private func makeArchive(
        kind: ArchiveKind,
        status: ArchiveStatus,
        url: URL? = nil,
        transcription: ArchiveTranscription? = nil
    ) -> Archive {
        Archive(
            id: UUID(),
            name: kind.rawValue,
            createdAt: Date(),
            status: status,
            url: url,
            size: 0,
            duration: 0,
            kind: kind,
            transcription: transcription)
    }
}
