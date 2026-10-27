//
//  Created by Vonage on 29/7/25.
//

import Combine
import Foundation
import SwiftUI
import Testing
import VERADomain
import VERAMeetingRoom
import VERATestHelpers

@MainActor
@Suite("DefaultCurrentCallParticipantsRepository tests")
struct DefaultCurrentCallParticipantsRepositoryTests {

    @Test func initialIsEmpty() async throws {
        let sut = makeSUT()
        let publisher = sut.getCurrentCallParticipants()
        let initialParticipants = currentParticipants(from: publisher)
        #expect(initialParticipants == [])
    }

    @Test func updateParticipantsPublishesNewValue() async throws {
        let sut = makeSUT()
        let participant = makeMockParticipant(id: "1", name: "Arthur Dent")
        sut.updateParticipants([participant])
        let publisher = sut.getCurrentCallParticipants()
        let published = currentParticipants(from: publisher)
        #expect(published == [participant])
    }

    @Test func updateMultipleTimesPublishesLatest() async throws {
        let sut = makeSUT()
        let p1 = makeMockParticipant(id: "1", name: "Arthur Dent")
        let p2 = makeMockParticipant(id: "2", name: "Ford Prefect", isMicEnabled: false)
        sut.updateParticipants([p1])
        sut.updateParticipants([p2])
        let publisher = sut.getCurrentCallParticipants()
        let published = currentParticipants(from: publisher)
        #expect(published == [p2])
    }

    // MARK: - Test Helpers

    /// The UI-owned repository synchronously replays its current participant snapshot.
    private func currentParticipants(from publisher: AnyPublisher<[Participant], Never>) -> [Participant]? {
        var participants: [Participant]?
        let subscription = publisher.first().sink { participants = $0 }
        defer { subscription.cancel() }
        return participants
    }

    private func makeSUT() -> DefaultCurrentCallParticipantsRepository {
        .init()
    }
}
