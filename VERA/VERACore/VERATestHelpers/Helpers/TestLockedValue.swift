//
//  Created by Vonage on 15/10/2026.
//

import Foundation

/// Synchronous test configuration and observations may be read while an async mock is running.
/// The value never escapes the lock; callers receive only Sendable snapshots.
final class TestLockedValue<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func withValue<Result: Sendable>(_ body: (inout Value) -> Result) -> Result {
        lock.withLock { body(&value) }
    }
}
