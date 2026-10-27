import Combine
import Foundation
import Testing

@testable import VERADomain

@Suite("Publisher relay ownership")
struct PublisherRelayTests {
    @Test("Concurrent producers deliver every value without overlapping downstream mutation")
    func concurrentProducers() async {
        let relay = EventRelay<Int, Never>()
        let received = RecordedValues()
        let subscription = relay.publisher.sink { received.append($0) }
        await Task.detached {
            DispatchQueue.concurrentPerform(iterations: 100) { relay.send($0) }
        }.value
        #expect(received.values.sorted() == Array(0..<100))
        subscription.cancel()
        relay.send(100)
        #expect(received.values.count == 100)
    }

    @Test("Concurrent current-value sends and reads preserve delivery and the final replay")
    func concurrentCurrentValueProducersAndReaders() async {
        let relay = CurrentValueRelay<Int, Never>(-1)
        let received = RecordedValues()
        let reads = RecordedValues()
        let subscription = relay.publisher.sink { received.append($0) }
        await Task.detached {
            DispatchQueue.concurrentPerform(iterations: 200) { iteration in
                if iteration.isMultiple(of: 2) {
                    relay.send(iteration / 2)
                } else {
                    for _ in 0..<32 {
                        reads.append(relay.value)
                    }
                }
            }
        }.value
        #expect(received.values.sorted() == [-1] + Array(0..<100))
        #expect(reads.values.count == 3200)
        #expect(reads.values.allSatisfy { (-1..<100).contains($0) })

        relay.send(100)
        #expect(relay.value == 100)
        let replay = RecordedValues()
        let replaySubscription = relay.publisher.sink { replay.append($0) }
        #expect(replay.values == [100])
        subscription.cancel()
        replaySubscription.cancel()
        relay.send(101)
        #expect(relay.value == 101)
        #expect(received.values.count == 102)
        #expect(replay.values == [100])
    }

    @Test("Current value replay supports a reentrant send without deadlocking")
    func replayAndReentrancy() {
        let relay = CurrentValueRelay<Int, Never>(0)
        let received = RecordedValues()
        let subscription = relay.publisher.sink {
            received.append($0)
            if $0 == 1 { relay.send(2) }
        }
        relay.send(1)
        #expect(received.values == [0, 1, 2])
        #expect(relay.value == 2)
        subscription.cancel()
    }

    @Test("Event relays do not replay history or emit after completion")
    func eventCompletion() {
        let relay = EventRelay<Int, Never>()
        relay.send(0)
        let received = RecordedValues()
        let subscription = relay.publisher.sink { received.append($0) }
        relay.send(1)
        relay.send(completion: .finished)
        relay.send(2)
        #expect(received.values == [1])
        subscription.cancel()
    }
}

/// Test observation storage; the lock protects all reads and writes.
private final class RecordedValues: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [Int] = []

    var values: [Int] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ value: Int) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(value)
    }
}
