import Foundation
import Testing

@testable import VERAVonage

@MainActor
@Suite("Bounded subscriber value updates", .timeLimit(.minutes(1)))
struct LatestValueWorkerTests {
    @Test("A suspended write keeps only the latest pending value")
    func burstCoalescesWhileWriteIsSuspended() async {
        let entered = ValueWorkerTestGate()
        let release = ValueWorkerTestGate()
        let latestWritten = ValueWorkerTestGate()
        var received: [Int] = []
        let worker = LatestValueWorker<Int> { value in
            received.append(value)
            if value == 1 {
                await entered.open()
                await release.wait()
            }
            if value == 100 { await latestWritten.open() }
        }
        worker.submit(1)
        await entered.wait()
        for value in 2...100 { worker.submit(value) }
        await release.open()
        await latestWritten.wait()
        await worker.cancel()?.value
        #expect(received == [1, 100])
    }

    @Test("Cancellation drops pending values and joins an operation that ignores cancellation")
    func cancellationJoinsTheLastWrite() async {
        let entered = ValueWorkerTestGate()
        let cancellationObserved = ValueWorkerTestGate()
        let release = ValueWorkerTestGate()
        var actions: [String] = []
        let worker = LatestValueWorker<Int> { value in
            actions.append("begin:\(value)")
            await entered.open()
            await withTaskCancellationHandler {
                await release.wait()
            } onCancel: {
                Task { await cancellationObserved.open() }
            }
            actions.append("written:\(value)")
        }
        worker.submit(1)
        await entered.wait()
        worker.submit(2)
        let handle = worker.cancel()
        var joined = false
        let join = Task {
            await handle?.value
            joined = true
        }
        await cancellationObserved.wait()
        #expect(!joined)
        worker.submit(3)
        await release.open()
        await join.value
        #expect(joined)
        #expect(actions == ["begin:1", "written:1"])
    }
}

actor ValueWorkerTestGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        let current = waiters
        waiters.removeAll()
        for waiter in current { waiter.resume() }
    }
}
