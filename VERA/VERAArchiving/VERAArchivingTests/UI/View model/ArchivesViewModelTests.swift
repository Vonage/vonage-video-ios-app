//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import Testing
import VERAArchiving
import VERADomain

@Suite("Archives view model tests")
struct ArchivesViewModelTests {

    @Test func initialArchivesAreEmpty() async {
        let sut = makeSUT()

        let archives = await sut.$archives.values.first { _ in true }

        #expect(archives?.isEmpty == true)
    }

    @Test func initialErrorIsNil() async {
        let sut = makeSUT()

        let error = await sut.$error.values.first { _ in true }

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
        #expect(repository.lastRoomName == "heart-of-gold")
    }

    @Test func loadDataMapsArchivesToUIData() async {
        let repository = SpyArchivesRepository()
        let archives = makeArchives()
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()
        repository.subject.send(archives)

        let uiArchives = await sut.$archives.values.first { !$0.isEmpty }

        #expect(uiArchives?.count == 2)
    }

    @Test func loadDataReversesArchivesOrder() async {
        let repository = SpyArchivesRepository()
        let archives = makeArchives()
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()
        repository.subject.send(archives)

        let uiArchives = await sut.$archives.values.first { !$0.isEmpty }

        // First archive should be the last one (reversed)
        #expect(uiArchives?.first?.id == archives.last?.id)
        #expect(uiArchives?.last?.id == archives.first?.id)
    }

    @Test func loadDataAssignsCorrectIndexes() async {
        let repository = SpyArchivesRepository()
        let archives = makeArchives()
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()
        repository.subject.send(archives)

        let uiArchives = await sut.$archives.values.first { !$0.isEmpty }

        #expect(uiArchives?.first?.title == "Recording 2")
        #expect(uiArchives?.last?.title == "Recording 1")
    }

    @Test func loadDataHandlesEmptyArchives() async {
        let repository = SpyArchivesRepository()
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()
        repository.subject.send([])

        try? await Task.sleep(for: .milliseconds(100))

        let uiArchives = await sut.$archives.values.first { _ in true }

        #expect(uiArchives?.isEmpty == true)
    }

    @Test func loadDataSetsErrorOnFailure() async {
        let repository = SpyArchivesRepository()
        repository.shouldFail = true
        let sut = makeSUT(archivesRepository: repository)

        await sut.loadData()

        let error = await sut.$error.values.first { $0 != nil }

        #expect(error != nil)
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
        #expect(uiArchive.title == "Recording 5")
        #expect(uiArchive.subtitle.contains("0:06"))
        #expect(uiArchive.subtitle.contains("3.2 MB"))
        #expect(uiArchive.isDownloadable == true)
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

        #expect(uiArchive.isDownloadable == false)
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

        let error = await sut.$error.values.first { $0 != nil }

        #expect(error != nil)
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

        let uiArchives = await sut.$archives.values.first { !$0.isEmpty }

        uiArchives?.first?.onDownload?()

        try? await Task.sleep(for: .milliseconds(100))

        #expect(playUseCase.callCount == 1)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        roomName: RoomName = "heart-of-gold",
        archivesRepository: ArchivesRepository = SpyArchivesRepository(),
        playRecordingUseCase: PlayRecordingUseCase = SpyPlayRecordingUseCase()
    ) -> ArchivesViewModel {
        ArchivesViewModel(
            roomName: roomName,
            archivesRepository: archivesRepository,
            playRecordingUseCase: playRecordingUseCase
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
    var lastRoomName: RoomName?
    var shouldFail = false
    let subject = PassthroughSubject<[Archive], Error>()

    func getArchives(roomName: RoomName) async -> AnyPublisher<[Archive], Error> {
        getArchivesCallCount += 1
        lastRoomName = roomName

        if shouldFail {
            return Fail(error: NSError(domain: "test", code: -1))
                .eraseToAnyPublisher()
        }

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
