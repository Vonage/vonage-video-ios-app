//
//  Created by Vonage on 13/10/25.
//

import Combine
import Foundation
import Testing
import VERAArchiving
import VERAArchivingTestHelpers
import VERAVonage
import VERAVonageArchivingPlugin

@Suite("Vonage Archiving Plugin tests")
struct VonageArchivingPluginTests {

    // MARK: - Call Lifecycle Tests

    @Test("Call did start does not throw")
    func callDidStartDoesNotThrow() async throws {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        try await sut.callDidStart([:])

        // Should not throw
    }

    @Test("Call did end resets archiving status")
    func callDidEndResetsArchivingStatus() async throws {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        try await sut.callDidEnd()

        #expect(dataSource.resetCallCount == 1)
    }

    // MARK: - Signal Handling Tests

    @Test("Handles archiving start signal correctly")
    func handlesArchivingStartSignalCorrectly() async throws {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)
        let archiveID = "test-archive-123"
        let jsonData = "{\"action\":\"start\",\"archivingID\":\"\(archiveID)\"}"

        let signal = VonageSignal(type: "archiving", data: jsonData)
        sut.handleSignal(signal)

        #expect(dataSource.setCallCount == 1)
        #expect(dataSource.lastArchivingStatus == .archiving(archiveID))
    }

    @Test("Handles archiving stop signal correctly")
    func handlesArchivingStopSignalCorrectly() async throws {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)
        let jsonData = "{\"action\":\"stop\"}"

        let signal = VonageSignal(type: "archiving", data: jsonData)
        sut.handleSignal(signal)

        #expect(dataSource.setCallCount == 1)
        #expect(dataSource.lastArchivingStatus == .idle)
    }

    @Test("Handles invalid archiving signal data gracefully")
    func handlesInvalidArchivingSignalDataGracefully() async throws {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        let signal = VonageSignal(type: "archiving", data: "invalid-json")
        sut.handleSignal(signal)

        #expect(dataSource.setCallCount == 0)
    }

    @Test("Ignores non-archiving signals")
    func ignoresNonArchivingSignals() async throws {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        let signal = VonageSignal(type: "chat", data: "some-message")
        sut.handleSignal(signal)

        #expect(dataSource.setCallCount == 0)
    }

    @Test("Handles multiple archiving signals in sequence")
    func handlesMultipleArchivingSignalsInSequence() async throws {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)
        let archiveID1 = "archive-1"
        let archiveID2 = "archive-2"

        // Start
        let startSignal1 = VonageSignal(
            type: "archiving", data: "{\"action\":\"start\",\"archivingID\":\"\(archiveID1)\"}")
        sut.handleSignal(startSignal1)

        #expect(dataSource.setCallCount == 1)
        #expect(dataSource.lastArchivingStatus == .archiving(archiveID1))

        // Stop
        let stopSignal = VonageSignal(type: "archiving", data: "{\"action\":\"stop\"}")
        sut.handleSignal(stopSignal)

        #expect(dataSource.setCallCount == 2)
        #expect(dataSource.lastArchivingStatus == .idle)

        // Start again with different ID
        let startSignal2 = VonageSignal(
            type: "archiving", data: "{\"action\":\"start\",\"archivingID\":\"\(archiveID2)\"}")
        sut.handleSignal(startSignal2)

        #expect(dataSource.setCallCount == 3)
        #expect(dataSource.lastArchivingStatus == .archiving(archiveID2))
    }

    @Test("Plugin identifier returns correct value")
    func pluginIdentifierReturnsCorrectValue() async throws {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        #expect(sut.pluginIdentifier == "VonageArchivingPlugin")
    }

    // MARK: - Test Helpers

    private func makeSUT(
        archivingStatusDataSource: ArchivingStatusDataSource
    ) -> VonageArchivingPlugin {
        VonageArchivingPlugin(archivingStatusDataSource: archivingStatusDataSource)
    }
}
