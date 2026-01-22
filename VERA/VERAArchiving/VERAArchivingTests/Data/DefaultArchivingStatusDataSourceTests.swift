//
//  Created by Vonage on 20/1/26.
//

import Combine
import Foundation
import Testing
import VERAArchiving

@Suite("Default archiving status data source tests")
struct DefaultArchivingStatusDataSourceTests {

    // MARK: - Initial State Tests

    @Test("Initial archiving status is false")
    func initialArchivingStatusIsFalse() async throws {
        let sut = makeSUT()

        let status = await sut.archivingStatus.nextValue()

        #expect(status == false)
    }

    // MARK: - Set Archiving Status Tests

    @Test("Setting archiving status to true updates publisher")
    func settingArchivingStatusToTrueUpdatesPublisher() async throws {
        let sut = makeSUT()

        sut.set(archivingStatus: true)

        let status = await sut.archivingStatus.nextValue()
        #expect(status == true)
    }

    @Test("Setting archiving status to false updates publisher")
    func settingArchivingStatusToFalseUpdatesPublisher() async throws {
        let sut = makeSUT()

        sut.set(archivingStatus: false)

        let status = await sut.archivingStatus.nextValue()
        #expect(status == false)
    }

    @Test("Setting archiving status multiple times updates publisher correctly")
    func settingArchivingStatusMultipleTimesUpdatesPublisherCorrectly() async throws {
        let sut = makeSUT()

        // Set to true
        sut.set(archivingStatus: true)
        var status = await sut.archivingStatus.nextValue()
        #expect(status == true)

        // Set to false
        sut.set(archivingStatus: false)
        status = await sut.archivingStatus.nextValue()
        #expect(status == false)

        // Set to true again
        sut.set(archivingStatus: true)
        status = await sut.archivingStatus.nextValue()
        #expect(status == true)
    }

    // MARK: - Reset Tests

    @Test("Reset sets archiving status to false")
    func resetSetsArchivingStatusToFalse() async throws {
        let sut = makeSUT()

        // Set to true first
        sut.set(archivingStatus: true)
        var status = await sut.archivingStatus.nextValue()
        #expect(status == true)

        // Reset
        sut.reset()
        status = await sut.archivingStatus.nextValue()
        #expect(status == false)
    }

    @Test("Reset when already false keeps status false")
    func resetWhenAlreadyFalseKeepsStatusFalse() async throws {
        let sut = makeSUT()

        // Initial state is already false
        var status = await sut.archivingStatus.nextValue()
        #expect(status == false)

        // Reset
        sut.reset()
        status = await sut.archivingStatus.nextValue()
        #expect(status == false)
    }

    @Test("Multiple resets keep status false")
    func multipleResetsKeepStatusFalse() async throws {
        let sut = makeSUT()

        sut.set(archivingStatus: true)

        // Multiple resets
        sut.reset()
        var status = await sut.archivingStatus.nextValue()
        #expect(status == false)

        sut.reset()
        status = await sut.archivingStatus.nextValue()
        #expect(status == false)

        sut.reset()
        status = await sut.archivingStatus.nextValue()
        #expect(status == false)
    }

    // MARK: - Test Helpers

    private func makeSUT() -> DefaultArchivingStatusDataSource {
        DefaultArchivingStatusDataSource()
    }
}

extension AnyPublisher where Failure == Never {
    func nextValue() async -> Output {
        await values.first { _ in true }!
    }
}
