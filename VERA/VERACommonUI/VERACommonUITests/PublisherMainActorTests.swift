import Combine
import Foundation
import Testing
import VERADomain

@testable import VERACommonUI

@Suite("Publisher main-actor delivery")
@MainActor
struct PublisherMainActorTests {
    @Test("Background values reach the UI owner in order before completion")
    func orderedBackgroundDelivery() async {
        let source = EventRelay<Int, DeliveryError>()
        var subscription: AnyCancellable?
        var received: [String] = []
        let result: [String] = await withCheckedContinuation { continuation in
            subscription = source.publisher.sinkOnMainActor(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished: received.append("finished")
                    case .failure: received.append("failure")
                    }
                    continuation.resume(returning: received)
                },
                receiveValue: { value in
                    MainActor.preconditionIsolated()
                    received.append(String(value))
                })
            Task.detached {
                source.send(1)
                source.send(2)
                source.send(completion: .failure(.expected))
            }
        }
        #expect(result == ["1", "2", "failure"])
        subscription?.cancel()
    }

    private enum DeliveryError: Error { case expected }
}
