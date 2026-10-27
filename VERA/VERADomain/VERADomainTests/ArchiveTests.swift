//
//  Created by Vonage on 18/10/26.
//

import Foundation
import Testing
import VERADomain

@Suite("Archive tests")
struct ArchiveTests {

    @Test("Maps every archive status reported by searchArchives", arguments: ArchiveStatus.allCases)
    func mapsKnownStatuses(status: ArchiveStatus) {
        #expect(ArchiveStatus(value: status.rawValue) == status)
    }

    @Test("Treats unknown statuses as failed")
    func treatsUnknownStatusesAsFailed() {
        #expect(ArchiveStatus(value: "something-new") == .failed)
    }

    @Test("Only in-progress statuses are pending")
    func pendingStatuses() {
        let pending = ArchiveStatus.allCases.filter(\.isPending)
        #expect(Set(pending) == [.requested, .started, .paused, .stopped])
    }

    @Test("A recording downloads its own media")
    func recordingDownloadsMedia() {
        let url = URL(string: "https://example.com/recording.mp4")
        let archive = makeArchive(kind: .recording, status: .available, url: url)

        #expect(archive.downloadURL == url)
        #expect(archive.isPending == false)
    }

    @Test("A recording that is not available has no download URL", arguments: [ArchiveStatus.stopped, .expired])
    func unavailableRecordingHasNoDownloadURL(status: ArchiveStatus) {
        let archive = makeArchive(
            kind: .recording, status: status, url: URL(string: "https://example.com/recording.mp4"))

        #expect(archive.downloadURL == nil)
    }

    @Test("A transcription downloads its transcript, not the parent media")
    func transcriptionDownloadsTranscript() {
        let transcriptURL = URL(string: "https://example.com/transcript.zip")
        let archive = makeArchive(
            kind: .transcription,
            status: .uploaded,
            url: URL(string: "https://example.com/audio.zip"),
            transcription: ArchiveTranscription(status: .available, url: transcriptURL))

        #expect(archive.downloadURL == transcriptURL)
        #expect(archive.isPending == false)
    }

    @Test(
        "A transcription stays pending after its parent archive finishes",
        arguments: [ArchiveStatus.uploaded, .available])
    func transcriptionPendingAfterParentFinishes(parentStatus: ArchiveStatus) {
        let archive = makeArchive(
            kind: .transcription,
            status: parentStatus,
            transcription: ArchiveTranscription(status: .started, url: nil))

        #expect(archive.downloadURL == nil)
        #expect(archive.isPending == true)
    }

    @Test("A transcription without a reported transcript follows its parent archive")
    func transcriptionWithoutTranscriptFollowsParent() {
        let archive = makeArchive(kind: .transcription, status: .stopped, url: nil)

        #expect(archive.downloadURL == nil)
        #expect(archive.isPending == true)
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
