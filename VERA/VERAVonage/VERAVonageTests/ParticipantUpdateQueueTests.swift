import SwiftUI
import Testing
import VERADomain

@testable import VERAVonage

@MainActor
@Suite("Subscriber participant update lifetime", .timeLimit(.minutes(1)))
struct ParticipantUpdateQueueTests {
    @Test("Same-ID replacement joins the old write and rejects its retired generation")
    func replacementJoinsOldRegistration() async {
        let queue = ParticipantUpdateQueue()
        let entered = ValueWorkerTestGate()
        let cancellationObserved = ValueWorkerTestGate()
        let release = ValueWorkerTestGate()
        let replacementWritten = ValueWorkerTestGate()
        var actions: [String] = []
        let oldGeneration = await queue.register(id: "remote") { _, _ in
            actions.append("old:begin")
            await entered.open()
            await withTaskCancellationHandler {
                await release.wait()
            } onCancel: {
                Task { await cancellationObserved.open() }
            }
            actions.append("old:written")
        }
        #expect(queue.contains(id: "remote", generation: oldGeneration))
        #expect(!queue.contains(id: "unknown", generation: oldGeneration))
        queue.submit(participant(), generation: oldGeneration)
        await entered.wait()
        var replacementRegistered = false
        let replacement = Task {
            let generation = await queue.register(id: "remote") { _, _ in
                actions.append("new:written")
                await replacementWritten.open()
            }
            replacementRegistered = true
            return generation
        }
        await cancellationObserved.wait()
        #expect(!replacementRegistered)
        await release.open()
        let newGeneration = await replacement.value
        #expect(!queue.contains(id: "remote", generation: oldGeneration))
        #expect(queue.contains(id: "remote", generation: newGeneration))
        queue.submit(participant(), generation: oldGeneration)
        queue.submit(participant(), generation: newGeneration)
        await replacementWritten.wait()
        await queue.stopAll()
        #expect(!queue.contains(id: "remote", generation: newGeneration))
        #expect(actions == ["old:begin", "old:written", "new:written"])
    }

    @Test("An update cannot create an actor repository entry after membership removal")
    func removedParticipantCannotBeReinsertedByUpdate() async {
        let repository = ParticipantsRepository()
        await repository.saveParticipant(participant())
        await repository.removeParticipant(id: "remote")
        await repository.updateExistingParticipant(participant())
        #expect(await repository.all.isEmpty)
    }

    private func participant() -> Participant {
        Participant(
            id: "remote", name: "Remote", isMicEnabled: true, isCameraEnabled: true,
            videoDimensions: .zero, creationTime: .distantPast, isScreenshare: false, view: AnyView(EmptyView()))
    }
}
