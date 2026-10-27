import Foundation

/// Serializes asynchronous value updates with one running operation and one latest pending value.
/// Cancellation drops pending work; callers join the returned handle before removing its target.
/// Explicit cancel-and-join is required for lifecycle teardown; deinit cancellation cannot join
/// a suspended operation that ignores cancellation.
@MainActor
final class LatestValueWorker<Value: Sendable> {
    private let operation: @MainActor (Value) async -> Void
    private var pending: Value?
    private var task: Task<Void, Never>?
    private var stopped = false

    init(operation: @escaping @MainActor (Value) async -> Void) {
        self.operation = operation
    }

    func submit(_ value: Value) {
        guard !stopped else { return }
        pending = value
        guard task == nil else { return }
        task = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled, let value = self.pending {
                self.pending = nil
                await self.operation(value)
            }
            self.task = nil
        }
    }

    /// Even if an operation ignores cancellation, awaiting this handle joins its final write.
    @discardableResult
    func cancel() -> Task<Void, Never>? {
        stopped = true
        pending = nil
        task?.cancel()
        return task
    }

    deinit { task?.cancel() }
}
