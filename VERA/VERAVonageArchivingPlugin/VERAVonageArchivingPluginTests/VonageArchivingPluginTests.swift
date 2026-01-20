//
//  Created by Vonage on 13/10/25.
//

import Combine
import Foundation
import Testing
import VERAArchiving
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

        let signal = VonageSignal(type: "archiving", data: "start")
        sut.handleSignal(signal)

        #expect(dataSource.setCallCount == 1)
        #expect(dataSource.lastArchivingStatus == true)
    }

    @Test("Handles archiving stop signal correctly")
    func handlesArchivingStopSignalCorrectly() async throws {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        let signal = VonageSignal(type: "archiving", data: "stop")
        sut.handleSignal(signal)

        #expect(dataSource.setCallCount == 1)
        #expect(dataSource.lastArchivingStatus == false)
    }

    @Test("Handles archiving signal with any non-start data as false")
    func handlesArchivingSignalWithAnyNonStartDataAsFalse() async throws {
        let dataSource = ArchivingStatusDataSourceSpy()
        let sut = makeSUT(archivingStatusDataSource: dataSource)

        let signal = VonageSignal(type: "archiving", data: "anything-else")
        sut.handleSignal(signal)

        #expect(dataSource.setCallCount == 1)
        #expect(dataSource.lastArchivingStatus == false)
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

        // Start
        let startSignal = VonageSignal(type: "archiving", data: "start")
        sut.handleSignal(startSignal)

        #expect(dataSource.setCallCount == 1)
        #expect(dataSource.lastArchivingStatus == true)

        // Stop
        let stopSignal = VonageSignal(type: "archiving", data: "stop")
        sut.handleSignal(stopSignal)

        #expect(dataSource.setCallCount == 2)
        #expect(dataSource.lastArchivingStatus == false)

        // Start again
        sut.handleSignal(startSignal)

        #expect(dataSource.setCallCount == 3)
        #expect(dataSource.lastArchivingStatus == true)
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
