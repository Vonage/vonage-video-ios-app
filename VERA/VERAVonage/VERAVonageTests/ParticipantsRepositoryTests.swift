import Foundation
import SwiftUI
import Testing
import VERADomain

@testable import VERAVonage

@MainActor
@Suite("Participant repository update ownership")
struct ParticipantsRepositoryTests {
    @Test("An update replaces an existing participant while preserving other participants")
    func replacesExistingParticipant() async {
        let sut = ParticipantsRepository()
        await sut.saveParticipant(makeParticipant(id: "arthur", name: "Arthur"))
        await sut.saveParticipant(makeParticipant(id: "ford", name: "Ford"))

        await sut.updateExistingParticipant(makeParticipant(id: "arthur", name: "Arthur Dent"))

        #expect(await sut.getParticipant(id: "arthur")?.name == "Arthur Dent")
        #expect(await sut.getParticipant(id: "ford")?.name == "Ford")
        #expect(await sut.all.count == 2)
    }

    @Test("Removal after an earlier membership read cannot be undone by a delayed update")
    func lateUpdateDoesNotReinsertRemovedParticipant() async throws {
        let sut = ParticipantsRepository()
        await sut.saveParticipant(makeParticipant(id: "arthur", name: "Arthur"))
        // This is the stale read held by the previous two-await check/save sequence.
        _ = try #require(await sut.getParticipant(id: "arthur"))
        await sut.removeParticipant(id: "arthur")

        await sut.updateExistingParticipant(makeParticipant(id: "arthur", name: "Late Arthur"))

        #expect(await sut.getParticipant(id: "arthur") == nil)
        #expect(await sut.all.isEmpty)
    }

    @Test("An update cannot register a participant that never joined")
    func ignoresUnknownParticipant() async {
        let sut = ParticipantsRepository()

        await sut.updateExistingParticipant(makeParticipant(id: "arthur", name: "Arthur"))

        #expect(await sut.all.isEmpty)
    }

    @Test("Call reset prevents delayed updates from restoring cleared participants")
    func lateUpdateDoesNotUndoReset() async {
        let sut = ParticipantsRepository()
        await sut.saveParticipant(makeParticipant(id: "arthur", name: "Arthur"))
        await sut.reset()

        await sut.updateExistingParticipant(makeParticipant(id: "arthur", name: "Late Arthur"))

        #expect(await sut.all.isEmpty)
    }

    @Test("The call manager returns cleared state after a late participant update")
    func callManagerDoesNotRestoreParticipantsAfterCleanup() async {
        let sut = CallStateManager(activeSpeakerTracker: ActiveSpeakerTracker())
        await sut.cleanUpParticipants()

        let state = await sut.updateParticipant(makeParticipant(id: "arthur", name: "Late Arthur"))

        #expect(state.participants.isEmpty)
        #expect(state.localParticipant == nil)
        #expect(state.activeParticipantId == nil)
        #expect(await sut.getSubscriber(id: "arthur") == nil)
    }

    private func makeParticipant(id: String, name: String) -> Participant {
        Participant(
            id: id,
            name: name,
            isMicEnabled: true,
            isCameraEnabled: true,
            videoDimensions: CGSize(width: 640, height: 480),
            creationTime: Date(),
            isScreenshare: false,
            view: AnyView(EmptyView())
        )
    }
}
