//
//  Created by Vonage on 17/10/26.
//

import Foundation

/// ``MotionActivityProviding`` that simulates a walking user, available on all
/// platforms. Intended for DEBUG/demos: after ``delay`` it emits walking/high
/// samples whose *timestamps* are spaced 5 s apart every 0.5 real seconds, so
/// the default 20 s sustained-motion threshold is crossed ~2 s after the first
/// sample.
@MainActor
public final class SimulatedMotionActivityProvider: MotionActivityProviding {

    /// Real seconds to wait before the first simulated sample.
    private let delay: TimeInterval

    /// Real seconds between emitted samples.
    private let emissionInterval: TimeInterval

    /// Seconds added to each successive sample's timestamp.
    private let timestampStep: TimeInterval

    private var task: Task<Void, Never>?

    public init(
        delay: TimeInterval = 3,
        emissionInterval: TimeInterval = 0.5,
        timestampStep: TimeInterval = 5
    ) {
        self.delay = delay
        self.emissionInterval = emissionInterval
        self.timestampStep = timestampStep
    }

    public var isAvailable: Bool { true }

    public var authorizationStatus: MotionAuthorizationStatus { .authorized }

    public func start(_ handler: @escaping @MainActor (MotionSample) -> Void) {
        task?.cancel()
        task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            var timestamp = Date()
            while !Task.isCancelled {
                handler(MotionSample(kind: .walking, confidence: .high, timestamp: timestamp))
                timestamp = timestamp.addingTimeInterval(timestampStep)
                try? await Task.sleep(nanoseconds: UInt64(emissionInterval * 1_000_000_000))
            }
        }
    }

    public func stop() {
        task?.cancel()
        task = nil
    }
}
