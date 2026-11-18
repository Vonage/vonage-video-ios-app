//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import Testing
import VERAArchiving
import VERADomain

@Suite("Default archiving status data source tests")
struct DefaultArchivingStatusDataSourceTests {

    // MARK: - Initial State Tests

    @Test("Initial archiving state is idle")
    func initialArchivingStateIsIdle() async throws {
        let sut = makeSUT()

        let status = await sut.archivingState(for: .recording).nextValue()

        #expect(status == .idle)
    }

    // MARK: - Set Archiving State Tests

    @Test("Setting archiving state to archiving updates publisher")
    func settingArchivingStateToArchivingUpdatesPublisher() async throws {
        let sut = makeSUT()
        let archiveID = "test-archive-123"

        sut.set(archivingState: .archiving(archiveID), for: .recording)

        let status = await sut.archivingState(for: .recording).nextValue()
        #expect(status == .archiving(archiveID))
    }

    @Test("Setting archiving state to idle updates publisher")
    func settingArchivingStateToIdleUpdatesPublisher() async throws {
        let sut = makeSUT()

        sut.set(archivingState: .idle, for: .recording)

        let status = await sut.archivingState(for: .recording).nextValue()
        #expect(status == .idle)
    }

    @Test("Setting archiving state multiple times updates publisher correctly")
    func settingArchivingStateMultipleTimesUpdatesPublisherCorrectly() async throws {
        let sut = makeSUT()
        let archiveID1 = "archive-1"
        let archiveID2 = "archive-2"

        // Set to archiving
        sut.set(archivingState: .archiving(archiveID1), for: .recording)
        var status = await sut.archivingState(for: .recording).nextValue()
        #expect(status == .archiving(archiveID1))

        // Set to idle
        sut.set(archivingState: .idle, for: .recording)
        status = await sut.archivingState(for: .recording).nextValue()
        #expect(status == .idle)

        // Set to archiving again with different ID
        sut.set(archivingState: .archiving(archiveID2), for: .recording)
        status = await sut.archivingState(for: .recording).nextValue()
        #expect(status == .archiving(archiveID2))
    }

    // MARK: - Reset Tests

    @Test("Reset sets archiving state to idle")
    func resetSetsArchivingStateToIdle() async throws {
        let sut = makeSUT()
        let archiveID = "test-archive"

        // Set to archiving first
        sut.set(archivingState: .archiving(archiveID), for: .recording)
        var status = await sut.archivingState(for: .recording).nextValue()
        #expect(status == .archiving(archiveID))

        // Reset
        sut.reset()
        status = await sut.archivingState(for: .recording).nextValue()
        #expect(status == .idle)
    }

    @Test("Reset when already idle keeps state idle")
    func resetWhenAlreadyIdleKeepsStateIdle() async throws {
        let sut = makeSUT()

        // Initial state is already idle
        var status = await sut.archivingState(for: .recording).nextValue()
        #expect(status == .idle)

        // Reset
        sut.reset()
        status = await sut.archivingState(for: .recording).nextValue()
        #expect(status == .idle)
    }

    @Test("Multiple resets keep state idle")
    func multipleResetsKeepStateIdle() async throws {
        let sut = makeSUT()
        let archiveID = "test-archive"

        sut.set(archivingState: .archiving(archiveID), for: .recording)

        // Multiple resets
        sut.reset()
        var status = await sut.archivingState(for: .recording).nextValue()
        #expect(status == .idle)

        sut.reset()
        status = await sut.archivingState(for: .recording).nextValue()
        #expect(status == .idle)

        sut.reset()
        status = await sut.archivingState(for: .recording).nextValue()
        #expect(status == .idle)
    }

    // MARK: - Archive Kind Tests

    @Test("Initial transcription state is idle")
    func initialTranscriptionStateIsIdle() async throws {
        let sut = makeSUT()

        let status = await sut.archivingState(for: .transcription).nextValue()

        #expect(status == .idle)
    }

    @Test("Setting the transcription state does not change the recording state")
    func settingTranscriptionStateKeepsRecordingState() async throws {
        let sut = makeSUT()

        sut.set(archivingState: .archiving("transcription-1"), for: .transcription)

        #expect(await sut.archivingState(for: .transcription).nextValue() == .archiving("transcription-1"))
        #expect(await sut.archivingState(for: .recording).nextValue() == .idle)
    }

    @Test("Stopping the recording keeps a running transcription")
    func stoppingRecordingKeepsTranscription() async throws {
        let sut = makeSUT()
        sut.set(archivingState: .archiving("recording-1"), for: .recording)
        sut.set(archivingState: .archiving("transcription-1"), for: .transcription)

        sut.set(archivingState: .idle, for: .recording)

        #expect(await sut.archivingState(for: .recording).nextValue() == .idle)
        #expect(await sut.archivingState(for: .transcription).nextValue() == .archiving("transcription-1"))
    }

    @Test("Reset sets every archive kind to idle")
    func resetSetsEveryKindToIdle() async throws {
        let sut = makeSUT()
        sut.set(archivingState: .archiving("recording-1"), for: .recording)
        sut.set(archivingState: .archiving("transcription-1"), for: .transcription)

        sut.reset()

        #expect(await sut.archivingState(for: .recording).nextValue() == .idle)
        #expect(await sut.archivingState(for: .transcription).nextValue() == .idle)
    }

    // MARK: - Test Helpers

    private func makeSUT() -> DefaultArchivingStatusDataSource {
        DefaultArchivingStatusDataSource()
    }
}

extension AnyPublisher where Failure == Never {
    @MainActor
    func nextValue() async -> Output {
        for await value in values { return value }
        preconditionFailure("Expected a value before publisher completion")
    }
}
