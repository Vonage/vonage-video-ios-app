//
//  Created by Vonage on 4/3/26.
//

func delay() async {
    try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
}

/// Extended delay to allow async Task-based autosave to complete.
/// Used when testing autosave with Task-based persistence.
func delayForAsyncPersistence() async {
    try? await Task.sleep(nanoseconds: 250_000_000)  // 0.25 seconds
}

/// Extra long delay for tests that are sensitive to timing.
func delayLong() async {
    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
}

/// Waits for auto-save to complete with deterministic synchronization.
/// Combines debounce delay with MainActor yield to ensure all pending Tasks complete.
///
/// - Parameter yields: Number of cooperative yields (default: 3 for multiple property changes)
func waitForAutoSave(yields: Int = 3) async {
    await delay()
    for _ in 0..<yields {
        await Task.yield()
    }
}
