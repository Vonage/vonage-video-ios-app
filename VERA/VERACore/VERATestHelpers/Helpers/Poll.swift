//
//  Created by Vonage on 23/9/26.
//

import Foundation

/// Polls an asynchronously-read value until `predicate` holds or `timeout` elapses,
/// returning the last value read.
///
/// Replaces the per-test `@Published.values` async sequences that were removed in the
/// `@Observable` migration. `read` is an `async` closure so callers can hop to the main
/// actor (`await MainActor.run { sut.state }`) or read a non-isolated value directly.
///
/// - Parameters:
///   - timeout: Maximum time to wait before returning the most recent value. Default 2s.
///   - pollInterval: Delay between reads. Default 10ms.
///   - read: Reads the current value.
///   - predicate: Returns `true` once the awaited condition is met.
/// - Returns: The value that satisfied `predicate`, or the last value read at timeout.
@discardableResult
public func poll<Value>(
    timeout: Duration = .seconds(2),
    pollInterval: UInt64 = 10_000_000,
    read: @escaping () async -> Value,
    until predicate: @escaping (Value) -> Bool
) async -> Value {
    let deadline = ContinuousClock.now.advanced(by: timeout)
    var value = await read()
    while !predicate(value) {
        if ContinuousClock.now >= deadline { return value }
        try? await Task.sleep(nanoseconds: pollInterval)
        value = await read()
    }
    return value
}
