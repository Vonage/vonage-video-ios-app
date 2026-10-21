//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import Testing
import VERAArchiving
import VERADomain
import VERATestHelpers

@Suite("Archives view model tests")
struct ArchivesViewModelTests {

    @Test func initialArchivesAreEmpty() async {
        let sut = makeSUT()

        let archives = await MainActor.run { sut.archives }

        #expect(archives.isEmpty == true)
    }

    @Test func initialErrorIsNil() async {
        let sut = makeSUT()

        let error = await MainActor.run { sut.error }

        #expect(error == nil as AlertItem?)
    }

    @Test func loadDataRetrievesArchivesFromRepository() async {
        let repository = SpyArchivesRepository()
        let archives = makeArchives()
        repository.subject.send(archives)
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()

        try? await Task.sleep(for: .milliseconds(100))

        #expect(repository.getArchivesCallCount == 1)
        #expect(repository.lastSessionKey == "heart-of-gold")
    }

    @Test func loadDataMapsArchivesToUIData() async {
        let repository = SpyArchivesRepository()
        let archives = makeArchives()
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()
        repository.subject.send(archives)

        let uiArchives = await poll(read: { await MainActor.run { sut.archives } }) { !$0.isEmpty }

        #expect(uiArchives.count == 2)
    }

    @Test func loadDataListsNewestArchiveFirst() async {
        let repository = SpyArchivesRepository()
        let archives = makeArchives()
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()
        repository.subject.send(archives)

        let uiArchives = await poll(read: { await MainActor.run { sut.archives } }) { !$0.isEmpty }

        // First archive should be the last one (reversed)
        #expect(uiArchives.first?.id == archives.last?.id)
        #expect(uiArchives.last?.id == archives.first?.id)
    }

    @Test func loadDataAssignsCorrectIndexes() async {
        let repository = SpyArchivesRepository()
        let archives = makeArchives()
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()
        repository.subject.send(archives)

        let uiArchives = await poll(read: { await MainActor.run { sut.archives } }) { !$0.isEmpty }

        // Verify indices are assigned correctly (first item gets highest index)
        #expect(uiArchives.first?.title.contains("2") == true)
        #expect(uiArchives.last?.title.contains("1") == true)
    }

    @Test func loadDataHandlesEmptyArchives() async {
        let repository = SpyArchivesRepository()
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()
        repository.subject.send([])

        try? await Task.sleep(for: .milliseconds(100))

        let uiArchives = await MainActor.run { sut.archives }

        #expect(uiArchives.isEmpty == true)
    }

    @Test func loadDataSetsErrorOnFailure() async {
        let repository = SpyArchivesRepository()
        repository.shouldFail = true
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()

        let error = await poll(read: { await MainActor.run { sut.error } }) { $0 != nil }

        #expect(error != nil)
    }

    @Test func loadDataClearsErrorFromEarlierLoad() async {
        let repository = SpyArchivesRepository()
        repository.shouldFail = true
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()
        let failedLoadError = await poll(read: { await MainActor.run { sut.error } }) { $0 != nil }
        #expect(failedLoadError != nil)

        repository.shouldFail = false
        await sut.loadData()

        #expect(await MainActor.run { sut.error } == nil)
    }

    @Test func loadDataIgnoresUpdatesFromEarlierLoad() async {
        let repository = SpyArchivesRepository()
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()
        let earlierSubject = repository.subject
        await sut.loadData()

        earlierSubject.send(makeArchives())
        try? await Task.sleep(for: .milliseconds(100))

        #expect(await MainActor.run { sut.archives }.isEmpty)
    }

    @Test func mapToUIArchiveCreatesCorrectUIData() {
        let archive = Archive(
            id: UUID(),
            name: "test-archive",
            createdAt: Date(timeIntervalSince1970: 1_737_395_280),  // Mon, Jan 20 4:48 PM 2025
            status: .available,
            url: URL(string: "https://example.com/archive"),
            size: 3_355_443,  // ~3.2 MB
            duration: 6  // 6 seconds
        )
        let sut = makeSUT()

        let uiArchive = sut.mapToUIArchive(archive, index: 5)

        #expect(uiArchive.id == archive.id)
        #expect(uiArchive.title.contains("5"))
        #expect(uiArchive.subtitle.contains("0:06"))
        #expect(uiArchive.subtitle.contains("3.2 MB"))
        #expect(uiArchive.downloadState == .ready)
    }

    @Test func mapToUIArchiveFormatsSmallSizeInKB() {
        let archive = Archive(
            id: UUID(),
            name: "test-archive",
            createdAt: Date(),
            status: .available,
            url: URL(string: "https://example.com/archive"),
            size: 51_200,  // 50 KB
            duration: 10
        )
        let sut = makeSUT()

        let uiArchive = sut.mapToUIArchive(archive, index: 1)

        #expect(uiArchive.subtitle.contains("50.0 KB"))
    }

    @Test func mapToUIArchiveFormatsLargeSizeInMB() {
        let archive = Archive(
            id: UUID(),
            name: "test-archive",
            createdAt: Date(),
            status: .available,
            url: URL(string: "https://example.com/archive"),
            size: 15_728_640,  // 15 MB
            duration: 10
        )
        let sut = makeSUT()

        let uiArchive = sut.mapToUIArchive(archive, index: 1)

        #expect(uiArchive.subtitle.contains("15 MB"))
    }

    @Test func mapToUIArchiveSetIsDownloadableFalseForNonAvailableArchives() {
        let archive = Archive(
            id: UUID(),
            name: "test-archive",
            createdAt: Date(),
            status: .stopped,
            url: nil,
            size: 0,
            duration: 0
        )
        let sut = makeSUT()

        let uiArchive = sut.mapToUIArchive(archive, index: 1)

        #expect(uiArchive.downloadState == .preparing)
    }

    @Test func downloadArchiveCallsPlayRecordingUseCase() async {
        let playUseCase = SpyPlayRecordingUseCase()
        let archive = Archive(
            id: UUID(),
            name: "test-archive",
            createdAt: Date(),
            status: .available,
            url: URL(string: "https://example.com/archive"),
            size: 1000,
            duration: 10
        )
        let sut = makeSUT(playRecordingUseCase: playUseCase)

        sut.downloadArchive(archive)

        try? await Task.sleep(for: .milliseconds(100))

        #expect(playUseCase.callCount == 1)
        #expect(playUseCase.lastArchive?.id == archive.id)
    }

    @Test func downloadArchiveSetsErrorOnFailure() async {
        let playUseCase = SpyPlayRecordingUseCase()
        playUseCase.shouldThrowError = true
        let archive = Archive(
            id: UUID(),
            name: "test-archive",
            createdAt: Date(),
            status: .available,
            url: URL(string: "https://example.com/archive"),
            size: 1000,
            duration: 10
        )
        let sut = makeSUT(playRecordingUseCase: playUseCase)

        sut.downloadArchive(archive)

        let error = await poll(read: { await MainActor.run { sut.error } }) { $0 != nil }

        #expect(error != nil)
    }

    @Test func loadDataNumbersRecordingsAndTranscriptionsSeparately() async {
        let repository = SpyArchivesRepository()
        // Newest first, as returned by `searchArchives`.
        let archives = [
            makeArchive(kind: .recording, createdAt: Date(timeIntervalSince1970: 300)),
            makeArchive(kind: .transcription, createdAt: Date(timeIntervalSince1970: 200)),
            makeArchive(kind: .recording, createdAt: Date(timeIntervalSince1970: 100)),
        ]
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()
        repository.subject.send(archives)

        let uiArchives = await poll(read: { await MainActor.run { sut.archives } }) { !$0.isEmpty }

        #expect(uiArchives.map(\.title) == ["Recording 2", "Transcription 1", "Recording 1"])
        #expect(uiArchives.map(\.kind) == [.recording, .transcription, .recording])
    }

    @Test func mapToUIArchivesListsNewestFirstAndNumbersOldestAsOne() {
        let first = makeArchive(kind: .transcription, createdAt: Date(timeIntervalSince1970: 100))
        let second = makeArchive(kind: .transcription, createdAt: Date(timeIntervalSince1970: 200))
        let sut = makeSUT()

        let uiArchives = sut.mapToUIArchives([second, first])

        #expect(uiArchives.map(\.id) == [second.id, first.id])
        #expect(uiArchives.map(\.title) == ["Transcription 2", "Transcription 1"])
    }

    @Test func mapToUIArchivesDoesNotDependOnResponseOrder() {
        let first = makeArchive(kind: .transcription, createdAt: Date(timeIntervalSince1970: 100))
        let second = makeArchive(kind: .transcription, createdAt: Date(timeIntervalSince1970: 200))
        let sut = makeSUT()

        let newestFirst = sut.mapToUIArchives([second, first])
        let oldestFirst = sut.mapToUIArchives([first, second])

        #expect(newestFirst.map(\.id) == oldestFirst.map(\.id))
        #expect(newestFirst.map(\.title) == oldestFirst.map(\.title))
    }

    @Test func mapToUIArchiveShowsTranscriptionReadyWhenTranscriptIsAvailable() {
        let archive = makeArchive(
            kind: .transcription,
            status: .uploaded,
            url: nil,
            transcription: ArchiveTranscription(
                status: .available, url: URL(string: "https://example.com/transcript.zip")))
        let sut = makeSUT()

        let uiArchive = sut.mapToUIArchive(archive, index: 3)

        #expect(uiArchive.kind == .transcription)
        #expect(uiArchive.title == "Transcription 3")
        #expect(uiArchive.downloadState == .ready)
    }

    @Test func mapToUIArchiveShowsTranscriptionPreparingWhileTranscriptIsPending() {
        let archive = makeArchive(
            kind: .transcription,
            status: .uploaded,
            transcription: ArchiveTranscription(status: .started, url: nil))
        let sut = makeSUT()

        let uiArchive = sut.mapToUIArchive(archive, index: 1)

        #expect(uiArchive.downloadState == .preparing)
        #expect(uiArchive.title == "Your transcription is being prepared")
        #expect(uiArchive.subtitle == "Please wait while we prepare your downloads")
    }

    @Test func mapToUIArchiveShowsRecordingPreparingWhileArchiveIsPending() {
        let archive = makeArchive(kind: .recording, status: .stopped, url: nil)
        let sut = makeSUT()

        let uiArchive = sut.mapToUIArchive(archive, index: 1)

        #expect(uiArchive.downloadState == .preparing)
        #expect(uiArchive.title == "Your recording is being prepared")
    }

    @Test(arguments: [ArchiveStatus.failed, .expired, .deleted, .uploaded])
    func mapToUIArchiveShowsRecordingUnavailableForFinishedNonDownloadableStatuses(status: ArchiveStatus) {
        let archive = makeArchive(kind: .recording, status: status, url: nil)
        let sut = makeSUT()

        let uiArchive = sut.mapToUIArchive(archive, index: 1)

        #expect(uiArchive.downloadState == .unavailable)
        #expect(uiArchive.title == "Recording 1")
    }

    @Test func mapToUIArchiveShowsTranscriptionUnavailableWhenTranscriptFailed() {
        let archive = makeArchive(
            kind: .transcription,
            status: .available,
            url: URL(string: "https://example.com/audio.zip"),
            transcription: ArchiveTranscription(status: .failed, url: nil))
        let sut = makeSUT()

        let uiArchive = sut.mapToUIArchive(archive, index: 1)

        #expect(uiArchive.downloadState == .unavailable)
    }

    @Test func downloadTranscriptionSharesDownloadedTranscript() async {
        let playUseCase = SpyPlayRecordingUseCase()
        let downloadUseCase = SpyDownloadTranscriptionUseCase()
        let archive = makeArchive(
            kind: .transcription,
            transcription: ArchiveTranscription(
                status: .available, url: URL(string: "https://example.com/transcript.zip")))
        let sut = makeSUT(playRecordingUseCase: playUseCase, downloadTranscriptionUseCase: downloadUseCase)

        sut.downloadArchive(archive)

        let transcript = await poll(read: { await MainActor.run { sut.sharedTranscript } }) { $0 != nil }

        #expect(transcript?.id == archive.id)
        #expect(downloadUseCase.lastArchive?.id == archive.id)
        #expect(playUseCase.callCount == 0)
    }

    @Test func downloadRecordingDoesNotDownloadTranscript() async {
        let playUseCase = SpyPlayRecordingUseCase()
        let downloadUseCase = SpyDownloadTranscriptionUseCase()
        let sut = makeSUT(playRecordingUseCase: playUseCase, downloadTranscriptionUseCase: downloadUseCase)

        sut.downloadArchive(makeArchive(kind: .recording))

        try? await Task.sleep(for: .milliseconds(100))

        #expect(playUseCase.callCount == 1)
        #expect(downloadUseCase.callCount == 0)
        #expect(await MainActor.run { sut.sharedTranscript } == nil)
    }

    @Test func downloadTranscriptionMarksArchiveDownloadingUntilFinished() async {
        let downloadUseCase = SpyDownloadTranscriptionUseCase()
        downloadUseCase.delay = .milliseconds(300)
        let archive = makeArchive(kind: .transcription)
        let sut = makeSUT(downloadTranscriptionUseCase: downloadUseCase)

        sut.downloadArchive(archive)

        let inProgress = await poll(read: { await MainActor.run { sut.downloadingArchiveIDs } }) { !$0.isEmpty }
        #expect(inProgress == [archive.id])

        let finished = await poll(read: { await MainActor.run { sut.downloadingArchiveIDs } }) { $0.isEmpty }
        #expect(finished.isEmpty)
        #expect(await MainActor.run { sut.sharedTranscript }?.id == archive.id)
    }

    @Test func downloadTranscriptionIgnoresRepeatedTapsWhileDownloading() async {
        let downloadUseCase = SpyDownloadTranscriptionUseCase()
        downloadUseCase.delay = .milliseconds(300)
        let archive = makeArchive(kind: .transcription)
        let sut = makeSUT(downloadTranscriptionUseCase: downloadUseCase)

        sut.downloadArchive(archive)
        sut.downloadArchive(archive)

        _ = await poll(read: { await MainActor.run { sut.sharedTranscript } }) { $0 != nil }
        #expect(downloadUseCase.callCount == 1)
    }

    @Test func downloadTranscriptionClearsDownloadingStateOnFailure() async {
        let downloadUseCase = SpyDownloadTranscriptionUseCase()
        downloadUseCase.shouldThrowError = true
        let sut = makeSUT(downloadTranscriptionUseCase: downloadUseCase)

        sut.downloadArchive(makeArchive(kind: .transcription))

        _ = await poll(read: { await MainActor.run { sut.error } }) { $0 != nil }
        #expect(await MainActor.run { sut.downloadingArchiveIDs }.isEmpty)
    }

    @Test func downloadTranscriptionSetsErrorOnFailure() async {
        let downloadUseCase = SpyDownloadTranscriptionUseCase()
        downloadUseCase.shouldThrowError = true
        let sut = makeSUT(downloadTranscriptionUseCase: downloadUseCase)

        sut.downloadArchive(makeArchive(kind: .transcription))

        let error = await poll(read: { await MainActor.run { sut.error } }) { $0 != nil }

        #expect(error != nil)
        #expect(await MainActor.run { sut.sharedTranscript } == nil)
    }

    @Test func uiArchiveOnDownloadTriggersDownloadArchive() async {
        let playUseCase = SpyPlayRecordingUseCase()
        let repository = SpyArchivesRepository()
        let archives = makeArchives()
        let sut = makeSUT(
            archivesRepository: repository,
            playRecordingUseCase: playUseCase
        )

        await sut.loadData()
        repository.subject.send(archives)

        let uiArchives = await poll(read: { await MainActor.run { sut.archives } }) { !$0.isEmpty }

        uiArchives.first?.onDownload?()

        try? await Task.sleep(for: .milliseconds(100))

        #expect(playUseCase.callCount == 1)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        sessionKey: String = "heart-of-gold",
        archivesRepository: ArchivesRepository = SpyArchivesRepository(),
        playRecordingUseCase: PlayRecordingUseCase = SpyPlayRecordingUseCase(),
        downloadTranscriptionUseCase: DownloadTranscriptionUseCase = SpyDownloadTranscriptionUseCase()
    ) -> ArchivesViewModel {
        let holder = DefaultSessionKeyHolder()
        holder.setSessionKey(sessionKey)
        return ArchivesViewModel(
            sessionKeyProvider: holder,
            archivesRepository: archivesRepository,
            playRecordingUseCase: playRecordingUseCase,
            downloadTranscriptionUseCase: downloadTranscriptionUseCase
        )
    }

    private func makeArchive(
        kind: ArchiveKind,
        status: ArchiveStatus = .available,
        url: URL? = URL(string: "https://example.com/archive"),
        transcription: ArchiveTranscription? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 1_737_395_160)
    ) -> Archive {
        Archive(
            id: UUID(),
            name: kind.rawValue,
            createdAt: createdAt,
            status: status,
            url: url,
            size: 1_048_576,
            duration: 30,
            kind: kind,
            transcription: transcription
        )
    }

    private func makeArchives() -> [Archive] {
        [
            Archive(
                id: UUID(),
                name: "archive-1",
                createdAt: Date(timeIntervalSince1970: 1_737_395_160),
                status: .available,
                url: URL(string: "https://example.com/archive1"),
                size: 1_048_576,
                duration: 30
            ),
            Archive(
                id: UUID(),
                name: "archive-2",
                createdAt: Date(timeIntervalSince1970: 1_737_395_280),
                status: .available,
                url: URL(string: "https://example.com/archive2"),
                size: 3_355_443,
                duration: 6
            ),
        ]
    }
}

// MARK: - Spies

final class SpyArchivesRepository: ArchivesRepository {
    var getArchivesCallCount = 0
    var lastSessionKey: String?
    var shouldFail = false
    /// Publisher returned by the latest `getArchives` call; each call gets a new one.
    private(set) var subject = PassthroughSubject<[Archive], Error>()

    func getArchives(sessionKey: String) async -> AnyPublisher<[Archive], Error> {
        getArchivesCallCount += 1
        lastSessionKey = sessionKey

        if shouldFail {
            return Fail(error: NSError(domain: "test", code: -1))
                .eraseToAnyPublisher()
        }

        subject = PassthroughSubject<[Archive], Error>()
        return subject.eraseToAnyPublisher()
    }
}

final class SpyPlayRecordingUseCase: PlayRecordingUseCase {
    var callCount = 0
    var lastArchive: Archive?
    var shouldThrowError = false

    func callAsFunction(_ archive: Archive) async throws {
        callCount += 1
        lastArchive = archive

        if shouldThrowError {
            throw NSError(domain: "test", code: -1)
        }
    }
}

final class SpyDownloadTranscriptionUseCase: DownloadTranscriptionUseCase {
    var callCount = 0
    var lastArchive: Archive?
    var shouldThrowError = false
    /// How long each download takes, so tests can observe the in-progress state.
    var delay: Duration = .zero

    func callAsFunction(_ archive: Archive) async throws -> ArchiveTranscript {
        callCount += 1
        lastArchive = archive
        try await Task.sleep(for: delay)

        if shouldThrowError {
            throw NSError(domain: "test", code: -1)
        }

        return ArchiveTranscript(id: archive.id, fileURL: URL(fileURLWithPath: "/tmp/transcript.zip"))
    }
}
