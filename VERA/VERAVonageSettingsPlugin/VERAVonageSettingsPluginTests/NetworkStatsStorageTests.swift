import Foundation
import Testing
import VERADomain

@testable import VERAVonageSettingsPlugin

@MainActor
@Suite("SDK statistics callback ownership", .timeLimit(.minutes(1)))
struct NetworkStatsStorageTests {
    private final class Source {}

    @Test("A removed connection cannot be recreated by a late callback")
    func removedSubscriberCannotReturn() async {
        let storage = NetworkStatsStorage()
        let source = Source()
        var received: NetworkMediaStats = .empty
        storage.setHandler { snapshot, _ in received = snapshot }
        storage.update(source: ObjectIdentifier(source), connectionId: "remote") { state, _ in
            state.ensureSubscriber("remote", name: "Before removal")
        }
        await nextMainLoopPass()
        #expect(received.subscriberStats.count == 1)
        storage.removeSubscriber(connectionId: "remote")
        storage.update(source: ObjectIdentifier(source), connectionId: "remote") { state, _ in
            state.ensureSubscriber("remote", name: "Late callback")
        }
        await nextMainLoopPass()
        #expect(received.subscriberStats.isEmpty)
    }

    @Test("Reset rejects old sources until an SDK object is registered again")
    func resetRejectsLateCallbacks() async {
        let storage = NetworkStatsStorage()
        let oldSource = Source()
        let newSource = Source()
        var received: NetworkMediaStats = .empty
        storage.setHandler { snapshot, _ in received = snapshot }
        storage.reset()
        storage.update(source: ObjectIdentifier(oldSource)) { state, _ in state.updatePublisherName("stale") }
        await nextMainLoopPass()
        #expect(received.publisherName.isEmpty)
        storage.registerPublisher(ObjectIdentifier(newSource))
        storage.update(source: ObjectIdentifier(newSource)) { state, _ in state.updatePublisherName("current") }
        storage.update(source: ObjectIdentifier(oldSource)) { state, _ in state.updatePublisherName("stale") }
        await nextMainLoopPass()
        #expect(received.publisherName == "current")
    }

    @Test("Reset delivers the snapshot of the reset state")
    func resetDeliversResetStateSnapshot() async {
        let storage = NetworkStatsStorage()
        let source = Source()
        var received: [NetworkMediaStats] = []
        storage.setHandler { snapshot, _ in received.append(snapshot) }
        storage.update(source: ObjectIdentifier(source), connectionId: "remote") { state, _ in
            state.ensureSubscriber("remote", name: "Remote")
        }
        await nextMainLoopPass()
        storage.reset()
        await nextMainLoopPass()
        #expect(received.last == .empty)
    }

    @Test("Mutations never run the handler before they return")
    func deliveryIsAlwaysAsynchronous() async {
        let storage = NetworkStatsStorage()
        let source = Source()
        var deliveries = 0
        storage.setHandler { _, _ in deliveries += 1 }
        storage.update(source: ObjectIdentifier(source)) { state, _ in state.updatePublisherName("name") }
        storage.removeSubscriber(connectionId: "remote")
        storage.reset()
        #expect(deliveries == 0)
        await nextMainLoopPass()
        #expect(deliveries == 1)
    }

    @Test("A reset from inside the handler is delivered later, never re-entering the handler")
    func resetDuringDeliveryIsNotReentrant() async {
        let storage = NetworkStatsStorage()
        let source = Source()
        var names: [String] = []
        var isDelivering = false
        var reentered = false
        storage.setHandler { snapshot, _ in
            if isDelivering { reentered = true }
            isDelivering = true
            defer { isDelivering = false }
            names.append(snapshot.publisherName)
            if snapshot.publisherName == "active" { storage.reset() }
        }
        storage.update(source: ObjectIdentifier(source)) { state, _ in state.updatePublisherName("active") }
        await nextMainLoopPass()
        await nextMainLoopPass()
        #expect(names == ["active", ""])
        #expect(!reentered)
    }

    @Test("Updates made within one main-loop pass are delivered once, with the latest state")
    func updatesWithinAPassAreCoalesced() async {
        let storage = NetworkStatsStorage()
        let source = Source()
        var names: [String] = []
        storage.setHandler { snapshot, _ in names.append(snapshot.publisherName) }
        for name in ["first", "second", "third"] {
            storage.update(source: ObjectIdentifier(source)) { state, _ in state.updatePublisherName(name) }
        }
        await nextMainLoopPass()
        #expect(names == ["third"])
    }

    @Test("Sustained updates yield other main-queue work between deliveries")
    func sustainedUpdatesYieldBetweenDeliveries() async {
        let storage = NetworkStatsStorage()
        let source = Source()
        let total = 20
        var deliveries = 0
        storage.setHandler { _, _ in
            deliveries += 1
            if deliveries < total {
                storage.update(source: ObjectIdentifier(source)) { state, _ in state.updatePublisherName("next") }
            }
        }
        storage.update(source: ObjectIdentifier(source)) { state, _ in state.updatePublisherName("first") }
        // Enqueued behind the first delivery; it must run before the next one.
        var deliveriesSeenByOtherWork = -1
        DispatchQueue.main.async { deliveriesSeenByOtherWork = deliveries }

        for _ in 0..<(total * 2) where deliveries < total {
            await nextMainLoopPass()
        }
        #expect(deliveriesSeenByOtherWork == 1)
        #expect(deliveries == total)
    }

    @Test("Changes and retries recorded before the handler is set are delivered to it")
    func changesBeforeHandlerAreDelivered() async {
        let storage = NetworkStatsStorage()
        let source = Source()
        storage.update(source: ObjectIdentifier(source), connectionId: "remote") { state, retryIDs in
            state.ensureSubscriber("remote", name: "Early")
            retryIDs.insert("remote")
        }
        await nextMainLoopPass()

        var received: NetworkMediaStats = .empty
        var receivedRetries: Set<String> = []
        storage.setHandler { snapshot, retries in
            received = snapshot
            receivedRetries = retries
        }
        await nextMainLoopPass()

        #expect(received.subscriberStats.first?.subscriberName == "Early")
        #expect(receivedRetries == ["remote"])
    }

    @Test("A replacement on the same connection cannot revive the retired SDK source")
    func replacementRejectsOldSource() async {
        let storage = NetworkStatsStorage()
        let oldSource = Source()
        let newSource = Source()
        var received: NetworkMediaStats = .empty
        storage.setHandler { snapshot, _ in received = snapshot }
        storage.registerSubscriber(ObjectIdentifier(oldSource), connectionId: "remote")
        storage.removeSubscriber(connectionId: "remote")
        storage.registerSubscriber(ObjectIdentifier(newSource), connectionId: "remote")
        storage.update(source: ObjectIdentifier(newSource), connectionId: "remote") { state, _ in
            state.ensureSubscriber("remote", name: "Current")
        }
        var staleCallbackApplied = false
        storage.update(source: ObjectIdentifier(oldSource), connectionId: "remote") { state, _ in
            staleCallbackApplied = true
            state.ensureSubscriber("remote", name: "Stale")
        }
        await nextMainLoopPass()
        #expect(!staleCallbackApplied)
        #expect(received.subscriberStats.first?.subscriberName == "Current")
    }

    @Test("Republishing retires callbacks from the previous publisher SDK object")
    func publisherReplacementRejectsOldSource() async {
        let storage = NetworkStatsStorage()
        let oldSource = Source()
        let newSource = Source()
        var received: NetworkMediaStats = .empty
        storage.setHandler { snapshot, _ in received = snapshot }
        storage.registerPublisher(ObjectIdentifier(oldSource))
        storage.update(source: ObjectIdentifier(oldSource)) { state, _ in state.updatePublisherName("Old") }
        storage.registerPublisher(ObjectIdentifier(newSource))
        storage.update(source: ObjectIdentifier(newSource)) { state, _ in state.updatePublisherName("Current") }
        storage.update(source: ObjectIdentifier(oldSource)) { state, _ in state.updatePublisherName("Late old") }
        await nextMainLoopPass()
        #expect(received.publisherName == "Current")
    }

    /// Waits until main-queue work enqueued before this call (such as a scheduled delivery) has run.
    private func nextMainLoopPass() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
