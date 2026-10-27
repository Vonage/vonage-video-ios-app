import Foundation
import Testing
import VERADomain

@testable import VERAVonageSettingsPlugin

@MainActor
@Suite("SDK statistics callback ownership", .timeLimit(.minutes(1)))
struct NetworkStatsStorageTests {
    private final class Source {}

    @Test("A removed connection cannot be recreated by a late callback")
    func removedSubscriberCannotReturn() {
        let storage = NetworkStatsStorage()
        let source = Source()
        var received: NetworkMediaStats = .empty
        storage.setHandler { snapshot, _ in received = snapshot }
        storage.update(source: ObjectIdentifier(source), connectionId: "remote") { state, _ in
            state.ensureSubscriber("remote", name: "Before removal")
        }
        #expect(received.subscriberStats.count == 1)
        storage.removeSubscriber(connectionId: "remote")
        storage.update(source: ObjectIdentifier(source), connectionId: "remote") { state, _ in
            state.ensureSubscriber("remote", name: "Late callback")
        }
        #expect(received.subscriberStats.isEmpty)
    }

    @Test("Reset rejects old sources until an SDK object is registered again")
    func resetRejectsLateCallbacks() {
        let storage = NetworkStatsStorage()
        let oldSource = Source()
        let newSource = Source()
        var received: NetworkMediaStats = .empty
        storage.setHandler { snapshot, _ in received = snapshot }
        storage.reset()
        storage.update(source: ObjectIdentifier(oldSource)) { state, _ in state.updatePublisherName("stale") }
        #expect(received.publisherName.isEmpty)
        storage.registerPublisher(ObjectIdentifier(newSource))
        storage.update(source: ObjectIdentifier(newSource)) { state, _ in state.updatePublisherName("current") }
        storage.update(source: ObjectIdentifier(oldSource)) { state, _ in state.updatePublisherName("stale") }
        #expect(received.publisherName == "current")
    }

    @Test("Synchronous subscribers can reset while handling a snapshot without deadlock")
    func resetDuringDeliveryIsReentrant() {
        let storage = NetworkStatsStorage()
        let source = Source()
        var names: [String] = []
        storage.setHandler { snapshot, _ in
            names.append(snapshot.publisherName)
            if snapshot.publisherName == "active" { storage.reset() }
        }
        storage.update(source: ObjectIdentifier(source)) { state, _ in state.updatePublisherName("active") }
        #expect(names == ["active", ""])
    }

    @Test("A replacement on the same connection cannot revive the retired SDK source")
    func replacementRejectsOldSource() {
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
        #expect(!staleCallbackApplied)
        #expect(received.subscriberStats.first?.subscriberName == "Current")
    }


    @Test("Sustained snapshot production yields after a bounded UI publication batch")
    func continuousSnapshotsYieldToTheUI() async {
        let storage = NetworkStatsStorage()
        let source = Source()
        var publicationCount = 0
        await withCheckedContinuation { continuation in
            storage.setHandler { _, _ in
                publicationCount += 1
                if publicationCount == 130 {
                    continuation.resume()
                } else {
                    storage.update(source: ObjectIdentifier(source)) { state, _ in
                        state.updatePublisherName("next")
                    }
                }
            }
            storage.update(source: ObjectIdentifier(source)) { state, _ in state.updatePublisherName("first") }
            #expect(publicationCount == 64)
        }
        #expect(publicationCount == 130)
    }


    @Test("Republishing retires callbacks from the previous publisher SDK object")
    func publisherReplacementRejectsOldSource() {
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
        #expect(received.publisherName == "Current")
    }

}
