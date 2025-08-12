//
//  Created by Vonage on 8/8/25.
//

import Foundation

public final class MovingAvgAudioLevelTracker {
    private var movingAvg: Float = 0.0
    private let smoothingFactor: Float = 0.7
    private let currentWeightFactor: Float = 0.3
    private let dbmScalingFactor: Float = 1.5
    private let normalizationOffset: Float = 1.0

    public init() {}

    /// Maps current audio level to a moving average value
    /// - Parameter audioLevel: Current audio level
    /// - Returns: Moving average and log moving average values.
    public func track(_ audioLevel: Float) -> (movingAvg: Float, logMovingAvg: Float) {
        if movingAvg <= audioLevel {
            movingAvg = audioLevel
        } else {
            movingAvg = smoothingFactor * movingAvg + currentWeightFactor * audioLevel
        }

        // 1.5 scaling to map the -30 - 0 dBm range to [0,1]
        let logLevel = log(movingAvg) / log(10.0) / dbmScalingFactor + normalizationOffset
        let normalizedLogLevel = min(max(logLevel, 0.0), normalizationOffset)

        return (movingAvg: movingAvg, logMovingAvg: normalizedLogLevel)
    }
}
