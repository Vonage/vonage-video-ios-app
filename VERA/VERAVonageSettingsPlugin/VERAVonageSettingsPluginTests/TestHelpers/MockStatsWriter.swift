//
//  Created by Vonage on 06/03/2026.
//

import VERADomain
import VERASettings

final class MockStatsWriter: StatsWriter, @unchecked Sendable {
    
    var updateStatsCallCount = 0
    var clearStatsCallCount = 0
    var lastStats: NetworkMediaStats?
    
    func updateStats(_ stats: NetworkMediaStats) async {
        updateStatsCallCount += 1
        lastStats = stats
    }
    
    func clearStats() async {
        clearStatsCallCount += 1
    }
}
