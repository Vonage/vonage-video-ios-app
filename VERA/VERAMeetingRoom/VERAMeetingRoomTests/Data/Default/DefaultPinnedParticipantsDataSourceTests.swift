//
//  Created by Vonage on 1/4/26.
//

import Testing

@testable import VERAMeetingRoom

@Suite("DefaultPinnedParticipantsDataSource tests")
struct DefaultPinnedParticipantsDataSourceTests {

    // MARK: - Initial State

    @Test func initialStateIsEmpty() async {
        let sut = makeSUT()
        var result: Set<String>?
        for await value in sut.pinnedParticipantIds.values {
            result = value
            break
        }
        #expect(result == [])
    }

    // MARK: - Toggle Pin

    @Test func togglePinAddsParticipant() async {
        let sut = makeSUT()
        await sut.togglePin(participantId: "1")
        var result: Set<String>?
        for await value in sut.pinnedParticipantIds.values {
            result = value
            break
        }
        #expect(result == ["1"])
    }

    @Test func togglePinTwiceRemovesParticipant() async {
        let sut = makeSUT()
        await sut.togglePin(participantId: "1")
        await sut.togglePin(participantId: "1")
        var result: Set<String>?
        for await value in sut.pinnedParticipantIds.values {
            result = value
            break
        }
        #expect(result == [])
    }

    @Test func togglePinMultipleParticipants() async {
        let sut = makeSUT()
        await sut.togglePin(participantId: "1")
        await sut.togglePin(participantId: "2")
        await sut.togglePin(participantId: "3")
        var result: Set<String>?
        for await value in sut.pinnedParticipantIds.values {
            result = value
            break
        }
        #expect(result == ["1", "2", "3"])
    }

    // MARK: - Reset

    @Test func resetClearsAllPinnedParticipants() async {
        let sut = makeSUT()
        await sut.togglePin(participantId: "1")
        await sut.togglePin(participantId: "2")
        await sut.reset()
        var result: Set<String>?
        for await value in sut.pinnedParticipantIds.values {
            result = value
            break
        }
        #expect(result == [])
    }

    // MARK: - Remove Participants Not In

    @Test func removeParticipantsNotInKeepsOnlyActiveIds() async {
        let sut = makeSUT()
        await sut.togglePin(participantId: "1")
        await sut.togglePin(participantId: "2")
        await sut.togglePin(participantId: "3")
        await sut.removeParticipants(notIn: ["1", "3"])
        var result: Set<String>?
        for await value in sut.pinnedParticipantIds.values {
            result = value
            break
        }
        #expect(result == ["1", "3"])
    }

    @Test func removeParticipantsNotInNoChangeWhenAllActive() async {
        let sut = makeSUT()
        await sut.togglePin(participantId: "1")
        await sut.togglePin(participantId: "2")
        await sut.removeParticipants(notIn: ["1", "2", "3"])
        var result: Set<String>?
        for await value in sut.pinnedParticipantIds.values {
            result = value
            break
        }
        #expect(result == ["1", "2"])
    }

    @Test func removeParticipantsNotInEmptySetClearsAll() async {
        let sut = makeSUT()
        await sut.togglePin(participantId: "1")
        await sut.togglePin(participantId: "2")
        await sut.removeParticipants(notIn: [])
        var result: Set<String>?
        for await value in sut.pinnedParticipantIds.values {
            result = value
            break
        }
        #expect(result == [])
    }

    // MARK: - Test Helpers

    private func makeSUT() -> DefaultPinnedParticipantsDataSource {
        DefaultPinnedParticipantsDataSource()
    }
}
