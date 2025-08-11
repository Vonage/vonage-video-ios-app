//
//  Created by Vonage on 8/8/25.
//

import Foundation

final class MovingAvgAudioLevelTracker {
    private var movingAvg: Float = 0.0
    
    /// Maps current audio level to a moving average value
    /// - Parameter audioLevel: Current audio level
    /// - Returns: Moving average and log moving average values.
    func track(audioLevel: Float) -> (movingAvg: Float, logMovingAvg: Float) {
        if movingAvg <= audioLevel {
            movingAvg = audioLevel
        } else {
            movingAvg = 0.7 * movingAvg + 0.3 * audioLevel
        }
        
        // 1.5 scaling to map the -30 - 0 dBm range to [0,1]
        let logLevel = log(movingAvg) / log(10.0) / 1.5 + 1.0
        let normalizedLogLevel = min(max(logLevel, 0.0), 1.0)
        
        return (movingAvg: movingAvg, logMovingAvg: normalizedLogLevel)
    }
}
