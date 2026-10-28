//
//  Created by Vonage on 12/10/2026.
//

import Testing
import VERADomain

@testable import VERAVonageSettingsPlugin

/// Exercises the actual collector subject without constructing publisher/subscriber SDK objects.
@MainActor
@Suite("Network statistics asynchronous delivery")
struct NetworkStatsEmissionTests {
    @Test("Resets and unknown removal deliver on a later main-queue pass")
    func deliversAfterReturning() async {
        let sut = makeSUT()
        var received: [NetworkMediaStats] = []
        let subscription = sut.statsPublisher.sink { received.append($0) }
        defer { subscription.cancel() }
        #expect(received == [.empty])
        sut.reset()
        #expect(received == [.empty])
        await delay()
        #expect(received == [.empty, .empty])
        sut.reset()
        await delay()
        #expect(received == [.empty, .empty, .empty])
        sut.removeSubscriber(connectionId: "unknown")
        await delay()
        #expect(received == [.empty, .empty, .empty, .empty])
    }

    @Test("A reset callback can reenter subscriber removal")
    func allowsReentrantRemoval() async {
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
        await delay()
        #expect(count == 3)
        var replay: NetworkMediaStats?
        let replaySubscription = sut.statsPublisher.sink { replay = $0 }
        defer { replaySubscription.cancel() }
        #expect(replay == .empty)
    }

    private func makeSUT() -> NetworkStatsCollector { NetworkStatsCollector() }
}
