//
//  Created by Vonage on 8/1/26.
//

import Foundation
import Testing
import VERAArchiving

@Suite("Start archiving use case tests")
struct StartArchivingUseCaseTests {

    @Test func startArchivingSucceeds() async throws {
        let sut = makeSUT()

        try await sut(.init(roomName: "heart-of-gold"))

        // No exception means that the function has successfully executed
    }

    @Test func startArchivingFailsBecauseOfANetworkIssue() async throws {
        let dataSourceMock = MockArchivingDataSource()
        dataSourceMock.error = ArchivingDataSourceError.networkError

        let sut = makeSUT(archivingDataSource: dataSourceMock)

        do {
            try await sut(.init(roomName: "heart-of-gold"))
            Issue.record("Should have thrown a networking error instead")
        } catch ArchivingDataSourceError.networkError {
            // Should throw an exception
        } catch {
            Issue.record("Expected networkError but got: \(error)")
        }
    }

    @Test func startArchivingFailsBecauseOfADataParsingIssue() async throws {
        let dataSourceMock = MockArchivingDataSource()
        dataSourceMock.error = ArchivingDataSourceError.invalidData

        let sut = makeSUT(archivingDataSource: dataSourceMock)

        do {
            try await sut(.init(roomName: "heart-of-gold"))
            Issue.record("Should have thrown a networking error instead")
        } catch ArchivingDataSourceError.invalidData {
            // Should throw an exception
        } catch {
            Issue.record("Expected networkError but got: \(error)")
        }
    }

    @Test func startArchivingPassesTheCorrectValues() async throws {
        let dataSourceMock = MockArchivingDataSource()
        let sut = makeSUT(archivingDataSource: dataSourceMock)

        let roomName = "heart-of-gold"
        try await sut(.init(roomName: roomName))

        #expect(dataSourceMock.lastRoomName == roomName)
    }

    // MARK: - Test Helpers

    private func makeSUT(
        archivingDataSource: any ArchivingDataSource = MockArchivingDataSource()
    ) -> StartArchivingUseCase {
        DefaultStartArchivingUseCase(archivingDataSource: archivingDataSource)
    }
}
