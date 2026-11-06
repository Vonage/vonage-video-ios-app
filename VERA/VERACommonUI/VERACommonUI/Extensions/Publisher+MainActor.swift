import Combine
import Foundation

extension Publisher where Failure == Never, Output: Sendable {
    /// Delivers checked Sendable values on the main queue before entering UI-owned code.
    /// This schedules delivery; cancellation retains Combine's normal semantics.
    public func sinkOnMainActor(
        receiveValue: @escaping @MainActor @Sendable (Output) -> Void
    ) -> AnyCancellable {
        receive(on: DispatchQueue.main)
            .sink { value in
                MainActor.assumeIsolated { receiveValue(value) }
            }
    }
}

extension Publisher where Output: Sendable {
    /// Delivers both terminal events and values through the same main-queue scheduler.
    public func sinkOnMainActor(
        receiveCompletion: @escaping @MainActor @Sendable (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping @MainActor @Sendable (Output) -> Void
    ) -> AnyCancellable {
        receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    MainActor.assumeIsolated { receiveCompletion(completion) }
                },
                receiveValue: { value in
                    MainActor.assumeIsolated { receiveValue(value) }
                })
    }
}
