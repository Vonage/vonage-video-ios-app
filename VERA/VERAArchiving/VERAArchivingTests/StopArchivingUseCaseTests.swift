//
//  Created by Vonage on 8/1/26.
//

import Foundation
import Testing
import VERAArchiving

@Suite("Stop archiving use case tests")
struct StopArchivingUseCaseTests {

    @Test func stopArchivingSucceeds() async throws {
        let sut = makeSUT()

        try await sut(.init(roomName: "heart-of-gold", archiveID: "anArchiveId"))

        // No exception means that the function has successfully executed
    }

    @Test func stopArchivingFailsBecauseOfANetworkIssue() async throws {
        let dataSourceMock = MockArchivingDataSource()
        dataSourceMock.error = ArchivingDataSourceError.networkError

        let sut = makeSUT(archivingDataSource: dataSourceMock)

        await #expect(throws: ArchivingDataSourceError.networkError) {
            try await sut(.init(roomName: "heart-of-gold", archiveID: "anArchiveId"))
        }
    }

    @Test func stopArchivingFailsBecauseOfADataParsingIssue() async throws {
        let dataSourceMock = MockArchivingDataSource()
        dataSourceMock.error = ArchivingDataSourceError.invalidData

        let sut = makeSUT(archivingDataSource: dataSourceMock)

        await #expect(throws: ArchivingDataSourceError.invalidData) {
            try await sut(.init(roomName: "heart-of-gold", archiveID: "anArchiveId"))
        }
    }

    @Test func stopArchivingPassesTheCorrectValues() async throws {
        let dataSourceMock = MockArchivingDataSource()
        let sut = makeSUT(archivingDataSource: dataSourceMock)

        let roomName = "heart-of-gold"
        let archiveId = "anArchiveId"
        try await sut(.init(roomName: roomName, archiveID: archiveId))

        #expect(dataSourceMock.lastRoomName == roomName)
        #expect(dataSourceMock.lastArchiveID == archiveId)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        archivingDataSource: any ArchivingDataSource = MockArchivingDataSource()
    ) -> StopArchivingUseCase {
        DefaultStopArchivingUseCase(archivingDataSource: archivingDataSource)
    }
}
