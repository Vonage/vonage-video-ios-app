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

    @Test("A busy UI coalesces display delivery after processing every audio sample")
    func audioSmoothingPrecedesCoalescing() async {
        let scheduler = ControlledDrainScheduler()
        let queue = MainActorEventQueue<Float>(
            transformEvent: Self.makeAudioTransform(), scheduleDrain: { scheduler.schedule($0) })
        let levels: [Float] = [1, 0.5, 0.25, 0.1]
        let reference = MovingAvgAudioLevelTracker()
        let expected = levels.map { reference.track($0).logMovingAvg }.last!
        var received: [Float] = []
        queue.setHandler { received.append($0) }

        await Task.detached {
            for level in levels { queue.send(level, replacing: "audio") }
        }.value
        #expect(received.isEmpty)
        #expect(scheduler.runNext())

        #expect(received.count == 1)
        #expect(received.first == expected)
        #expect(expected != MovingAvgAudioLevelTracker().track(levels.last!).logMovingAvg)
        #expect(!scheduler.runNext())
    }

    @Test("A sustained control burst is drained in bounded batches")
    func controlBurstYieldsBetweenBatches() async {
        let scheduler = ControlledDrainScheduler()
        let queue = MainActorEventQueue<Int>(scheduleDrain: { scheduler.schedule($0) })
        var received: [Int] = []
        queue.setHandler { received.append($0) }
        await Task.detached {
            for value in 0..<130 { queue.send(value) }
        }.value

        #expect(received.isEmpty)
        #expect(scheduler.runNext())
        #expect(received == Array(0..<64))
        #expect(scheduler.runNext())
        #expect(received == Array(0..<128))
        #expect(scheduler.runNext())
        #expect(received == Array(0..<130))
        #expect(!scheduler.runNext())
    }

    @Test("The default drain scheduler lets other UI work run between batches")
    func defaultSchedulerYieldsBetweenBatches() async {
        let queue = MainActorEventQueue<Int>()
        var received: [Int] = []
        var countAtSentinel: Int?
        await withCheckedContinuation { continuation in
            queue.setHandler { value in
                received.append(value)
                if value == 0 {
                    // Reentrant sends queue the whole burst without blocking a producer or actor.
                    for next in 1...130 { queue.send(next) }
                }
                if value == 1 {
                    DispatchQueue.main.async { countAtSentinel = received.count }
                }
                if value == 130 { continuation.resume() }
            }
            queue.send(0)
        }
        #expect(received == Array(0...130))
        #expect(countAtSentinel == 65)
    }

    @Test("Explicit setup starts a new callback lifetime without replaying invalidated values")
    func activationDropsTheOldBatch() async {
        let scheduler = ControlledDrainScheduler()
        let queue = MainActorEventQueue<Int>(scheduleDrain: { scheduler.schedule($0) })
        var oldValues: [Int] = []
        var newValues: [Int] = []
        queue.setHandler { value in
            oldValues.append(value)
            queue.invalidate()
            queue.send(500)
            queue.activate { newValues.append($0) }
            queue.send(1000)
        }
        await Task.detached {
            for value in 0..<100 { queue.send(value) }
        }.value

        #expect(scheduler.runNext())
        #expect(oldValues == [0])
        #expect(newValues.isEmpty)
        #expect(scheduler.runNext())
        #expect(newValues == [1000])
        #expect(!scheduler.runNext())
    }

    // The queue invokes this lock-confined transformation on producer threads.
    nonisolated private static func makeAudioTransform() -> (Float) -> Float {
        let tracker = MovingAvgAudioLevelTracker()
        return { tracker.track($0).logMovingAvg }
    }
}

/// Only pending operations cross producer threads; every access uses the same lock.
/// Drains are taken out of the lock and executed exclusively by MainActor test code.
private final class ControlledDrainScheduler: @unchecked Sendable {
    private let lock = NSLock()
    private var pending: [@MainActor @Sendable () -> Void] = []

    func schedule(_ operation: @escaping @MainActor @Sendable () -> Void) {
        lock.withLock { pending.append(operation) }
    }

    @MainActor @discardableResult
    func runNext() -> Bool {
        let operation = lock.withLock { pending.isEmpty ? nil : pending.removeFirst() }
        guard let operation else { return false }
        operation()
        return true
    }
}
