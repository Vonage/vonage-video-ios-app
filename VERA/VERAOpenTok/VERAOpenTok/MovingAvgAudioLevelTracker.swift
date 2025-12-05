//
//  Created by Vonage on 8/8/25.
//

import Foundation

/// Tracks audio level using an exponential moving average and a normalized log scale.
///
/// This utility smooths raw audio level samples into a moving average that reacts
/// quickly to rising levels and decays smoothly on falling levels.
///
/// ## Details
/// - Rising levels: snap to current sample to keep meters responsive
/// - Falling levels: apply smoothing (`movingAvg = α * movingAvg + β * sample`)
/// - Normalization: `log10(movingAvg) / 1.5 + 1` clamped to `[0, 1]`
///
/// - Note: The `dbmScalingFactor` and `normalizationOffset` are tuned to map
///   a typical OpenTok audio range (around -30 to 0 dBm) into `[0, 1]`.
public final class MovingAvgAudioLevelTracker {
    private var movingAvg: Float = 0.0
    private let smoothingFactor: Float = 0.7
    private let currentWeightFactor: Float = 0.3
    private let dbmScalingFactor: Float = 1.5
    private let normalizationOffset: Float = 1.0

    /// Creates an audio level tracker.
    public init() {}

    /// Updates the tracker with the current audio level and returns smoothed values.
    ///
    /// - Parameter audioLevel: Current audio level sample (linear scale).
    /// - Returns: A tuple:
    ///   - `movingAvg`: Exponentially smoothed audio level
    ///   - `logMovingAvg`: Normalized log10 value in `[0, 1]` for UI meters
    public func track(_ audioLevel: Float) -> (movingAvg: Float, logMovingAvg: Float) {
        if movingAvg <= audioLevel {
            movingAvg = audioLevel
        } else {
            movingAvg = smoothingFactor * movingAvg + currentWeightFactor * audioLevel
        }

        // Map to a normalized log scale suitable for UI visualization.
        let logLevel = log(movingAvg) / log(10.0) / dbmScalingFactor + normalizationOffset
        let normalizedLogLevel = min(max(logLevel, 0.0), normalizationOffset)

        return (movingAvg: movingAvg, logMovingAvg: normalizedLogLevel)
    }
}
