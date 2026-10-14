//
//  Created by Vonage on 12/10/2026.
//

import VERADomain
import VERASettings

/// Blocks the first write without honoring cancellation. Tests release it explicitly.
actor ControlledStatsWriter: StatsWriter {
    let firstWriteEntered = StatsTestGate()
    let firstWriteCancelled = StatsTestGate()
    let releaseFirstWrite = StatsTestGate()
    let firstWriteCompleted = StatsTestGate()
    let secondWriteCompleted = StatsTestGate()
    let firstClearEntered = StatsTestGate()
    let releaseFirstClear = StatsTestGate()
    private let suspendFirstClear: Bool
    private var clearCount = 0
    private var writeCount = 0
    private(set) var actions: [String] = []

    init(suspendFirstClear: Bool = false) {
        self.suspendFirstClear = suspendFirstClear
    }

    func updateStats(_ stats: NetworkMediaStats) async {
        writeCount += 1
        let index = writeCount
        if index == 1 {
            await firstWriteEntered.open()
            await withTaskCancellationHandler {
                await releaseFirstWrite.wait()
            } onCancel: { [firstWriteCancelled] in
                Task { await firstWriteCancelled.open() }
            }
        }
        actions.append("update:\(stats.sentAudio?.bytesSent ?? 0)")
        if index == 1 { await firstWriteCompleted.open() }
        if index == 2 { await secondWriteCompleted.open() }
    }

    func clearStats() async {
        clearCount += 1
        if suspendFirstClear && clearCount == 1 {
            actions.append("clear:start")
            await firstClearEntered.open()
            await releaseFirstClear.wait()
        }
        actions.append("clear")
    }
}

/// One-shot continuation barrier. No clock delays or thread/actor affinity assumptions.
actor StatsTestGate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        guard !isOpen else { return }
        isOpen = true
        let pending = waiters
        waiters.removeAll()
        for waiter in pending {
            waiter.resume()
        }
    }
}
