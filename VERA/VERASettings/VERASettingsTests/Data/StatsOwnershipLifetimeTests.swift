import Combine
import Testing
import VERADomain

@testable import VERASettings

@Suite("Statistics ownership and lifetime")
struct StatsOwnershipLifetimeTests {
    @Test("An observer can read, subscribe and cancel reentrantly during a send")
    func reentrantSubscriptionAndCancellation() async {
        let repository = InMemoryStatsRepository()
        let nested = StatsSnapshotRecorder()
        let recorder = StatsSnapshotRecorder()
        let token = repository.statsPublisher.sink { stats in
            recorder.append(stats)
            guard stats.publisherName == "trigger" else { return }
            let nestedToken = repository.statsPublisher.sink { nested.append($0) }
            nestedToken.cancel()
        }
        let trigger = NetworkMediaStats(publisherName: "trigger")
        let later = NetworkMediaStats(publisherName: "later")
        await repository.updateStats(trigger)
        await repository.updateStats(later)
        #expect(recorder.values == [.empty, trigger, later])
        #expect(nested.values == [trigger])
        token.cancel()
    }

    @Test("A subscriber can cancel itself through prefix during delivery")
    func cancellationDuringDelivery() async {
        let repository = InMemoryStatsRepository()
        let recorder = StatsSnapshotRecorder()
        let token = repository.statsPublisher.prefix(2).sink { recorder.append($0) }
        let first = NetworkMediaStats(publisherName: "first")
        await repository.updateStats(first)
        await repository.updateStats(NetworkMediaStats(publisherName: "ignored"))
        await repository.clearStats()
        #expect(recorder.values == [.empty, first])
        token.cancel()
    }

    @Test("Canceled observers receive no subsequent updates or clear")
    func canceledObserverStopsReceiving() async {
        let repository = InMemoryStatsRepository()
        let recorder = StatsSnapshotRecorder()
        let token = repository.statsPublisher.sink { recorder.append($0) }
        token.cancel()
        await repository.updateStats(NetworkMediaStats(publisherName: "ignored"))
        await repository.clearStats()
        #expect(recorder.values == [.empty])
    }

    @Test("Cancellation releases state captured by the downstream closure")
    func cancellationReleasesObserver() throws {
        let repository = InMemoryStatsRepository()
        var witness: ObserverWitness? = ObserverWitness()
        let weakWitness = WeakReference(witness)
        let token = try makeObserver(repository: repository, witness: witness)
        witness = nil
        #expect(weakWitness.value != nil)
        token.cancel()
        #expect(weakWitness.value == nil)
    }

    @Test("A retained publisher does not retain its repository actor")
    func publisherDoesNotRetainRepository() throws {
        var repository: InMemoryStatsRepository? = InMemoryStatsRepository()
        let weakRepository = WeakReference(repository)
        let publisher = try #require(repository).statsPublisher
        repository = nil
        #expect(weakRepository.value == nil)
        let recorder = StatsSnapshotRecorder()
        let token = publisher.sink { recorder.append($0) }
        #expect(recorder.values == [.empty])
        token.cancel()
    }

    @Test("Subscription, replay and cancellation can race with actor writes")
    func concurrentObservationAndWrites() async {
        let repository = InMemoryStatsRepository()
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<64 {
                group.addTask {
                    await repository.updateStats(NetworkMediaStats(publisherName: String(index)))
                }
                group.addTask {
                    let recorder = StatsSnapshotRecorder()
                    let token = repository.statsPublisher.sink { recorder.append($0) }
                    #expect(!recorder.values.isEmpty)
                    token.cancel()
                }
            }
        }
        await repository.clearStats()
        let recorder = StatsSnapshotRecorder()
        let token = repository.statsPublisher.sink { recorder.append($0) }
        #expect(recorder.values == [.empty])
        token.cancel()
    }

    @Test("Awaited writes preserve order, replay latest and remain reusable after clear")
    func orderedWritesAndClear() async {
        let repository: any StatsRepository = InMemoryStatsRepository()
        let first = NetworkMediaStats(publisherName: "first")
        let second = NetworkMediaStats(publisherName: "second")
        let afterClear = NetworkMediaStats(publisherName: "after clear")
        let recorder = StatsSnapshotRecorder()
        let token = repository.statsPublisher.sink { recorder.append($0) }
        #expect(recorder.values == [.empty])
        await repository.updateStats(first)
        await repository.updateStats(second)
        let lateRecorder = StatsSnapshotRecorder()
        let lateToken = repository.statsPublisher.sink { lateRecorder.append($0) }
        #expect(lateRecorder.values == [second])
        await repository.clearStats()
        await repository.updateStats(afterClear)
        #expect(recorder.values == [.empty, first, second, .empty, afterClear])
        #expect(lateRecorder.values == [second, .empty, afterClear])
        token.cancel()
        lateToken.cancel()
    }

    @Test("Unlimited-demand observers receive every concurrent write in the same actor order")
    func concurrentWritesReachBothObservers() async {
        let repository = InMemoryStatsRepository()
        let first = StatsSnapshotRecorder()
        let second = StatsSnapshotRecorder()
        let firstToken = repository.statsPublisher.sink { first.append($0) }
        let secondToken = repository.statsPublisher.sink { second.append($0) }
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<64 {
                group.addTask {
                    await repository.updateStats(NetworkMediaStats(publisherName: String(index)))
                }
            }
        }
        let snapshots = first.values
        #expect(snapshots.count == 65)
        #expect(snapshots.first == .empty)
        #expect(Set(snapshots.dropFirst().map(\.publisherName)) == Set((0..<64).map(String.init)))
        #expect(second.values == snapshots)
        let latest = StatsSnapshotRecorder()
        let latestToken = repository.statsPublisher.sink { latest.append($0) }
        #expect(latest.values == Array(snapshots.suffix(1)))
        firstToken.cancel()
        secondToken.cancel()
        latestToken.cancel()
    }

}

private final class ObserverWitness: Sendable {
    let recorder = StatsSnapshotRecorder()
}

private func makeObserver(repository: InMemoryStatsRepository, witness: ObserverWitness?) throws -> AnyCancellable {
    let captured = try #require(witness)
    return repository.statsPublisher.sink { stats in
        captured.recorder.append(stats)
    }
}

private final class WeakReference<Value: AnyObject> {
    weak var value: Value?

    init(_ value: Value?) {
        self.value = value
    }
}
