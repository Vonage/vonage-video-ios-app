//
//  Created by Vonage on 7/6/26.
//

import Combine
import Testing
import VERAArchiving
import VERADomain

@testable import VERAE2E

@Suite("E2E archiving data source tests")
struct E2EArchivingDataSourceTests {

    @Test("Archiving data source delegates and updates call archiving state")
    func e2EArchivingDataSourceDelegatesAndUpdatesCallArchivingState() async throws {
        let decorated = ArchivingDataSourceStub()
        let statusDataSource = ArchivingStatusDataSourceStub()
        let sut = E2EArchivingDataSource(
            decorated: decorated,
            archivingStatusDataSource: statusDataSource)
        let call = E2ECallFacade()

        var archivingStates = [ArchivingState]()
        let cancellable = call.archivingState.sink { state in
            archivingStates.append(state)
        }

        let startResponse = try await sut.startArchiving(
            StartArchivingDataSourceRequest(sessionKey: "session-key"))
        let stopResponse = try await sut.stopArchiving(
            StopArchivingDataSourceRequest(
                sessionKey: "session-key",
                archiveID: startResponse.archiveId))

        #expect(decorated.didStartArchiving)
        #expect(decorated.didStopArchiving)
        #expect(startResponse.archiveId == "archive-id")
        #expect(stopResponse.archiveId == "archive-id")
        #expect(statusDataSource.states == [.archiving("archive-id"), .idle])
        #expect(archivingStates.contains(.archiving("archive-id")))
        #expect(archivingStates.last == .idle)
        cancellable.cancel()
    }
}

private final class ArchivingDataSourceStub: ArchivingDataSource {
    private(set) var didStartArchiving = false
    private(set) var didStopArchiving = false

    func startArchiving(
        _ request: StartArchivingDataSourceRequest
    ) async throws -> StartArchivingDataSourceResponse {
        didStartArchiving = true
        return StartArchivingDataSourceResponse(archiveId: "archive-id")
    }

    func stopArchiving(
        _ request: StopArchivingDataSourceRequest
    ) async throws -> StopArchivingDataSourceResponse {
        didStopArchiving = true
        return StopArchivingDataSourceResponse(archiveId: request.archiveID)
    }
}

private final class ArchivingStatusDataSourceStub: ArchivingStatusDataSource {
    private let subject = CurrentValueSubject<ArchivingState, Never>(.idle)
    private(set) var states: [ArchivingState] = []

    var archivingState: AnyPublisher<ArchivingState, Never> {
        subject.eraseToAnyPublisher()
    }

    func set(archivingState: ArchivingState) {
        states.append(archivingState)
        subject.send(archivingState)
    }

    func reset() {
        set(archivingState: .idle)
    }
}
