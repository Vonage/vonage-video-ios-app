//
//  Created by Vonage on 8/1/26.
//

import Foundation
import Testing
import VERAArchiving
import VERADomain

@Suite("Stop archiving use case tests")
struct StopArchivingUseCaseTests {

    @Test func stopArchivingSucceeds() async throws {
        let sut = makeSUT()

        try await sut(.init(sessionKey: "heart-of-gold", archiveID: "anArchiveId"))

        // No exception means that the function has successfully executed
    }

    @Test func stopArchivingFailsBecauseOfANetworkIssue() async throws {
        let dataSourceMock = MockArchivingDataSource()
        dataSourceMock.error = ArchivingDataSourceError.networkError

        let sut = makeSUT(archivingDataSource: dataSourceMock)

        await #expect(throws: ArchivingDataSourceError.networkError) {
            try await sut(.init(sessionKey: "heart-of-gold", archiveID: "anArchiveId"))
        }
    }

    @Test func stopArchivingFailsBecauseOfADataParsingIssue() async throws {
        let dataSourceMock = MockArchivingDataSource()
        dataSourceMock.error = ArchivingDataSourceError.invalidData

        let sut = makeSUT(archivingDataSource: dataSourceMock)

        await #expect(throws: ArchivingDataSourceError.invalidData) {
            try await sut(.init(sessionKey: "heart-of-gold", archiveID: "anArchiveId"))
        }
    }

    @Test func stopArchivingPassesTheCorrectValues() async throws {
        let dataSourceMock = MockArchivingDataSource()
        let sut = makeSUT(archivingDataSource: dataSourceMock)

        let sessionKey = "heart-of-gold"
        let archiveId = "anArchiveId"
        try await sut(.init(sessionKey: sessionKey, archiveID: archiveId))

        #expect(dataSourceMock.lastSessionKey == sessionKey)
        #expect(dataSourceMock.lastArchiveID == archiveId)
    }

    @Test func stopArchivingPassesTheTranscriptionKindAndArchiveID() async throws {
        let dataSourceMock = MockArchivingDataSource()
        let sut = makeSUT(archivingDataSource: dataSourceMock)

        try await sut(.init(sessionKey: "heart-of-gold", archiveID: "transcription-1", kind: .transcription))

        #expect(dataSourceMock.lastArchiveID == "transcription-1")
        #expect(dataSourceMock.lastStopKind == .transcription)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        archivingDataSource: any ArchivingDataSource = MockArchivingDataSource()
    ) -> StopArchivingUseCase {
        DefaultStopArchivingUseCase(archivingDataSource: archivingDataSource)
    }
}
