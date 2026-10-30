import Foundation

/// One bounded recovery workflow. The owner resets the budget only after the SDK confirms success.
@MainActor
final class VideoRecovery {
    private(set) var attempts = 0
    private var pending: Task<Void, Never>?
    private var generation = UUID()
    var wait: (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }

    func beginAttempt() {
        attempts += 1
    }

    @discardableResult
    func schedule(policy: VideoRecoveryPolicy, error: Error, operation: @escaping @MainActor () async -> Void) -> Bool {
        guard policy.permits(error), attempts < 3 else { return false }
        guard pending == nil else { return true }
        let generation = generation
        let delay = UInt64(max(1, attempts)) * 3_000_000_000
        pending = Task { [weak self, wait] in
            do {
                try await wait(delay)
                try Task.checkCancellation()
            } catch { return }
            guard let self, self.generation == generation else { return }
            self.pending = nil
            await operation()
        }
        return true
    }

    func cancel() {
        generation = UUID()
        pending?.cancel()
        pending = nil
    }

    func reset() {
        cancel()
        attempts = 0
    }

    deinit {
        pending?.cancel()
    }
}
