import Foundation
import Testing

@testable import VERAVonage

@MainActor
@Suite("SDK callback UI delivery", .timeLimit(.minutes(1)))
struct MainActorEventQueueTests {
    @Test("Background control events arrive in order on the UI actor")
    func backgroundEventsPreserveOrder() async {
        let queue = MainActorEventQueue<Int>()
        var received: [Int] = []
        await withCheckedContinuation { continuation in
            queue.setHandler { value in
                received.append(value)
                if value == 99 { continuation.resume() }
            }
            Task.detached {
                for value in 0..<100 { queue.send(value) }
            }
        }
        #expect(received == Array(0..<100))
    }

    @Test("A reentrant handler can append another event without holding the queue lock")
    func reentrantEventsDoNotDeadlock() async {
        let queue = MainActorEventQueue<Int>()
        var received: [Int] = []
        await withCheckedContinuation { continuation in
            queue.setHandler { value in
                received.append(value)
                if value == 1 { queue.send(2) }
                if value == 2 { continuation.resume() }
            }
            queue.send(1)
        }
        #expect(received == [1, 2])
        queue.invalidate()
    }

    @Test("Cleanup during delivery prevents queued and later callbacks")
    func invalidationDropsLateCallbacks() async {
        let queue = MainActorEventQueue<Int>()
        var received: [Int] = []
        await withCheckedContinuation { continuation in
            queue.setHandler { value in
                received.append(value)
                queue.invalidate()
                continuation.resume()
            }
            Task.detached {
                for value in 0..<100 { queue.send(value) }
            }
        }
        queue.send(100)
        #expect(received == [0])
    }

    @Test("A sustained control burst yields to other UI work after a bounded batch")
    func controlBurstYieldsBetweenBatches() async {
        let queue = MainActorEventQueue<Int>()
        let produced = DispatchSemaphore(value: 0)
        var received: [Int] = []
        var countAtSentinel: Int?
        await withCheckedContinuation { continuation in
            queue.setHandler { value in
                received.append(value)
                if value == 129 { continuation.resume() }
            }
            DispatchQueue.global().async {
                for value in 0..<130 { queue.send(value) }
                produced.signal()
            }
            #expect(produced.wait(timeout: .now() + 2) == .success)
            DispatchQueue.main.async { countAtSentinel = received.count }
        }
        #expect(received == Array(0..<130))
        #expect(countAtSentinel == 64)
    }

    @Test("Explicit setup starts a new callback lifetime without replaying invalidated values")
    func activationDropsTheOldBatch() async {
        let queue = MainActorEventQueue<Int>()
        let produced = DispatchSemaphore(value: 0)
        var oldValues: [Int] = []
        var newValues: [Int] = []
        await withCheckedContinuation { continuation in
            queue.setHandler { value in
                oldValues.append(value)
                queue.invalidate()
                queue.send(500)
                queue.activate { value in
                    newValues.append(value)
                    continuation.resume()
                }
                queue.send(1000)
            }
            DispatchQueue.global().async {
                for value in 0..<100 { queue.send(value) }
                produced.signal()
            }
            #expect(produced.wait(timeout: .now() + 2) == .success)
        }
        #expect(oldValues == [0])
        #expect(newValues == [1000])
    }

}
