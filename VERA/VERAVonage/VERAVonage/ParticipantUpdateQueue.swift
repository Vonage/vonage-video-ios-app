import Foundation
import VERADomain

/// Bounds subscriber observation work and invalidates old registrations before teardown.
/// Lifecycle callers must serialize register/remove/stopAll across their awaits; VonageCall
/// uses its stream-control task chain and joins that chain before stopping all registrations.
/// Value submissions may reenter while a lifecycle operation is suspended.
@MainActor
final class ParticipantUpdateQueue {
    private struct Registration {
        let generation: UUID
        let worker: LatestValueWorker<Participant>
    }
    private var registrations: [String: Registration] = [:]

    func register(
        id: String,
        update: @escaping @MainActor (Participant, UUID) async -> Void
    ) async -> UUID {
        await remove(id: id)
        let generation = UUID()
        registrations[id] = Registration(
            generation: generation,
            worker: LatestValueWorker { participant in await update(participant, generation) })
        return generation
    }

    func submit(_ participant: Participant, generation: UUID) {
        guard let registration = registrations[participant.id],
            registration.generation == generation
        else { return }
        registration.worker.submit(participant)
    }

    func contains(id: String, generation: UUID) -> Bool {
        registrations[id]?.generation == generation
    }

    func remove(id: String) async {
        let worker = registrations.removeValue(forKey: id)?.worker
        await worker?.cancel()?.value
    }

    func stopAll() async {
        let tasks = registrations.values.compactMap { $0.worker.cancel() }
        registrations.removeAll()
        for task in tasks { await task.value }
    }
}
