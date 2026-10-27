import Combine
import Foundation
import Testing

@testable import VERACommonUI

@MainActor
@Suite("UI-owned publisher completion delivery")
struct PublisherCompletionUIStateDeliveryTests {
    @Test("Background values and failure enter the UI actor in source order")
    func preservesValueAndFailureOrder() async {
        var received: [Int] = []
        var subscription: AnyCancellable?
        await withCheckedContinuation { continuation in
            subscription = [1, 2].publisher
                .setFailureType(to: TestFailure.self)
                .append(Fail<Int, TestFailure>(error: TestFailure()))
                .subscribe(on: DispatchQueue(label: "ui-completion-delivery-test"))
                .sinkOnMainActor(
                    receiveCompletion: { completion in
                        MainActor.preconditionIsolated()
                        if case .failure = completion { received.append(3) }
                        continuation.resume()
                    },
                    receiveValue: { value in
                        MainActor.preconditionIsolated()
                        received.append(value)
                    })
        }
        subscription?.cancel()
        #expect(received == [1, 2, 3])
    }

    @Test("Cancellation discards queued values and terminal completion")
    func cancellationDiscardsQueuedCompletion() async {
        let source = PassthroughSubject<Int, TestFailure>()
        var received = false
        let subscription = source.sinkOnMainActor(
            receiveCompletion: { _ in received = true },
            receiveValue: { _ in received = true })
        source.send(1)
        source.send(completion: .failure(TestFailure()))
        subscription.cancel()
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
        #expect(!received)
    }

    private struct TestFailure: Error {}
}
