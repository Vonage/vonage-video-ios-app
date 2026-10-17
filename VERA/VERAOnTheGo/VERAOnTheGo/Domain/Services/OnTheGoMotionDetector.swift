//
//  Created by Vonage on 17/10/26.
//

import Foundation

/// Pure debounce logic for sustained-motion detection.
///
/// Fed ``MotionSample``s and fires ``onSustainedMotion`` exactly once when
/// moving samples have spanned at least ``threshold`` seconds with no
/// non-moving sample in between. A stationary/unknown sample or a
/// low-confidence sample resets the run start. After firing, further samples
/// are ignored until ``reset()`` is called.
///
/// Uses each sample's `timestamp` (not the wall clock), so tests and
/// simulated providers can compress time.
///
/// Call from the main actor.
@MainActor
public final class OnTheGoMotionDetector {

    /// Default sustained-motion threshold in seconds.
    public static let defaultSustainedMotionThreshold: TimeInterval = 20

    /// Called once when sustained motion reaches the threshold.
    public var onSustainedMotion: (@MainActor () -> Void)?

    /// Whether the detector has already fired since the last ``reset()``.
    public private(set) var hasFired = false

    private let threshold: TimeInterval
    private var runStart: Date?

    /// Uses ``defaultSustainedMotionThreshold``.
    ///
    /// Kept off the parameter list because default arguments are nonisolated
    /// and this type is main-actor isolated.
    public convenience init() {
        self.init(threshold: Self.defaultSustainedMotionThreshold)
    }

    public init(threshold: TimeInterval) {
        self.threshold = threshold
    }

    /// Feeds a motion sample into the detector.
    public func ingest(_ sample: MotionSample) {
        guard !hasFired else { return }
        guard sample.isMoving else {
            runStart = nil
            return
        }
        let start = runStart ?? sample.timestamp
        runStart = start
        if sample.timestamp.timeIntervalSince(start) >= threshold {
            hasFired = true
            runStart = nil
            onSustainedMotion?()
        }
    }

    /// Clears the fired flag and any in-flight run.
    public func reset() {
        hasFired = false
        runStart = nil
    }
}
