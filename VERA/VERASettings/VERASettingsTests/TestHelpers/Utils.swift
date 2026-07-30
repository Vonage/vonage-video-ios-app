//
//  Created by Vonage on 4/3/26.
//

import Foundation

func delay() async {
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
}

/// Polls `condition` every 50ms until it returns `true` or `timeout` is reached.
///
/// Prefer this over `delay()` when testing async Combine pipelines that involve
/// multiple dispatch hops (e.g. `receive(on:)` followed by a nested `Task { @MainActor in }`),
/// where a fixed sleep may not be long enough on slower machines.
///
/// - Parameters:
///   - timeout: Maximum time to wait in seconds. Defaults to 2.0.
///   - condition: Closure that returns `true` when the expected state has been reached.
/// - Throws: If `timeout` expires before `condition` becomes `true`.
func waitUntil(
    timeout: TimeInterval = 2.0,
    condition: @MainActor () -> Bool
) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    let pollInterval: UInt64 = 50_000_000  // 50ms
    while Date() < deadline {
        if await condition() { return }
        try await Task.sleep(nanoseconds: pollInterval)
    }
    // One final check — if it just became true, accept it
    if await condition() { return }
    throw TestTimeoutError(timeout: timeout)
}

struct TestTimeoutError: Error, CustomStringConvertible {
    let timeout: TimeInterval
    var description: String { "Condition not met within \(timeout)s" }
}
