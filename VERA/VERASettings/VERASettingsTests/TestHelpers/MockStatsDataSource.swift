//
//  Created by Vonage on 06/03/2026.
//

import Combine
import VERADomain

@testable import VERASettings

final class MockStatsDataSource: StatsDataSource {

    private nonisolated  let subject: CurrentValueSubject<NetworkMediaStats, Never>
    
    nonisolated(unsafe) private(set) var startCallCount = 0
    nonisolated(unsafe) private(set) var stopCallCount = 0

    init(initialStats: NetworkMediaStats = .empty) {
        self.subject = CurrentValueSubject(initialStats)
    }

    nonisolated var  statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.eraseToAnyPublisher()
    }

    func start() {
        startCallCount += 1
    }

    func stop() {
        stopCallCount += 1
    }

    func updateStats(_ stats: NetworkMediaStats) async {
        subject.send(stats)
    }
}
