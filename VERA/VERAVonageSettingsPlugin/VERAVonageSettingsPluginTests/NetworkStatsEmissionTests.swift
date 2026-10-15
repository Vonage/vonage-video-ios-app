//
//  Created by Vonage on 12/10/2026.
//

import Testing
import VERADomain

@testable import VERAVonageSettingsPlugin

/// Exercises the actual collector subject without constructing publisher/subscriber SDK objects.
@Suite("Network statistics synchronous delivery")
struct NetworkStatsEmissionTests {
    @Test("Initial replay, repeated resets and unknown removal deliver before returning")
    func preservesSynchronousDelivery() {
        let sut = makeSUT()
        var received: [NetworkMediaStats] = []
        let subscription = sut.statsPublisher.sink { received.append($0) }
        defer { subscription.cancel() }
        #expect(received == [.empty])
        sut.reset()
        #expect(received == [.empty, .empty])
        sut.reset()
        #expect(received == [.empty, .empty, .empty])
        sut.removeSubscriber(connectionId: "unknown")
        #expect(received == [.empty, .empty, .empty, .empty])
    }

    @Test("A reset callback can synchronously reenter subscriber removal")
    func allowsReentrantRemoval() {
        let sut = makeSUT()
        var count = 0
        var reenter = false
        let subscription = sut.statsPublisher.sink { _ in
            count += 1
            if reenter {
                reenter = false
                sut.removeSubscriber(connectionId: "unknown")
            }
        }
        defer { subscription.cancel() }
        reenter = true
        sut.reset()
        #expect(count == 3)
        var replay: NetworkMediaStats?
        let replaySubscription = sut.statsPublisher.sink { replay = $0 }
        defer { replaySubscription.cancel() }
        #expect(replay == .empty)
    }

    private func makeSUT() -> NetworkStatsCollector { NetworkStatsCollector() }
}
