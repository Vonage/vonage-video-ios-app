import VERADomain
import os

/// Observer-owned state, protected independently of the repository's delivery context.
final class StatsSnapshotRecorder: Sendable {
    private let storage = OSAllocatedUnfairLock(initialState: [NetworkMediaStats]())

    func append(_ value: NetworkMediaStats) {
        storage.withLock { $0.append(value) }
    }

    var values: [NetworkMediaStats] {
        storage.withLock { $0 }
    }
}
