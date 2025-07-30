//
//  Created by Vonage on 29/7/25.
//

import Foundation
import SwiftUI
import Testing
import VERACore
import VERATestHelpers

@Suite("DefaultCurrentCallParticipantsRepository tests")
struct DefaultCurrentCallParticipantsRepositoryTests {

    @Test func initialIsEmpty() async throws {
        let sut = makeSUT()
        let publisher = sut.getCurrentCallParticipants()
        var initialParticipants: [Participant]? = nil
        for await value in publisher.values {
            initialParticipants = value
            break
        }
        #expect(initialParticipants == [])
    }

    @Test func updateParticipantsPublishesNewValue() async throws {
        let sut = makeSUT()
        let participant = makeMockParticipant(id: "1", name: "Arthur Dent")
        sut.updateParticipants([participant])
        let publisher = sut.getCurrentCallParticipants()
        var published: [Participant]? = nil
        for await value in publisher.values {
            published = value
            break
        }
        #expect(published == [participant])
    }

    @Test func updateMultipleTimesPublishesLatest() async throws {
        let sut = makeSUT()
        let p1 = makeMockParticipant(id: "1", name: "Arthur Dent")
        let p2 = makeMockParticipant(id: "2", name: "Ford Prefect", isMicEnabled: false)
        sut.updateParticipants([p1])
        sut.updateParticipants([p2])
        let publisher = sut.getCurrentCallParticipants()
        var published: [Participant]? = nil
        for await value in publisher.values {
            published = value
            break
        }
        #expect(published == [p2])
    }

    // MARK: - Test Helpers

    private func makeSUT() -> DefaultCurrentCallParticipantsRepository {
        .init()
    }
}
