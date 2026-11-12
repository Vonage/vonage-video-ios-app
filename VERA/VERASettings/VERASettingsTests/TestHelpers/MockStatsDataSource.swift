//
//  Created by Vonage on 06/03/2026.
//

import Combine
import VERADomain

@testable import VERASettings

actor MockStatsDataSource: StatsDataSource {

    private nonisolated let subject: CurrentValueRelay<NetworkMediaStats, Never>

    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    init(initialStats: NetworkMediaStats = .empty) {
        self.subject = CurrentValueRelay(initialStats)
    }

    nonisolated var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.publisher
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
