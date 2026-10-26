import Combine
import Foundation
import Testing

@testable import VERACommonUI

@MainActor
@Suite("UI-owned publisher delivery")
struct PublisherUIStateDeliveryTests {
    @Test("Background values enter the UI actor in emission order")
    func orderedBackgroundDelivery() async {
        let queue = DispatchQueue(label: "PublisherUIStateDeliveryTests.background")
        var subscription: AnyCancellable?
        var observed: [Emission] = []
        let received: [Emission] = await withCheckedContinuation { continuation in
            subscription = [1, 2, 3].publisher
                .subscribe(on: queue)
                .map { @Sendable value in Emission(value: value, wasMainThread: Thread.isMainThread) }
                .sinkOnMainActor { emission in
                    MainActor.preconditionIsolated()
                    observed.append(emission)
                    if observed.count == 3 {
                        continuation.resume(returning: observed)
                    }
                }
        }
        subscription?.cancel()

        #expect(received.map(\.value) == [1, 2, 3])
        #expect(received.allSatisfy { !$0.wasMainThread })
    }

    @Test("Cancelling before queued UI delivery discards the value")
    func cancellationDiscardsQueuedDelivery() async {
        let source = PassthroughSubject<Int, Never>()
        var received: [Int] = []
        let subscription = source.sinkOnMainActor { received.append($0) }

        source.send(1)
        subscription.cancel()
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }

        #expect(received.isEmpty)
    }

    private struct Emission: Sendable {
        let value: Int
        let wasMainThread: Bool
    }
}
