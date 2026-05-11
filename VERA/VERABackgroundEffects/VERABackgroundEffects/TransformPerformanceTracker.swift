//
//  Created by Vonage on 11/5/26.
//

import Combine
import Foundation

/// Rolling-window performance counters for the Apple Vision pipeline.
///
/// The transformer writes per-frame samples on its capture-side background thread.
/// `@Published` values are updated on the main actor at a throttled rate so SwiftUI
/// bindings don't get hammered at the capture frame rate. The HUD view observes
/// this instance directly.
///
/// Used for live in-app comparison between providers — for the Vonage path the
/// internal pipeline is opaque, so only `framesPerSecond` reflects useful data;
/// `transformMs` and `visionMs` will be zero.
public final class TransformPerformanceTracker: ObservableObject {

    /// Shared instance. Acceptable as a singleton because the counters are
    /// process-global instrumentation data, not application state.
    public static let shared = TransformPerformanceTracker()

    // MARK: - Published

    @Published public private(set) var framesPerSecond: Double = 0
    @Published public private(set) var transformMs: Double = 0
    @Published public private(set) var visionMs: Double = 0
    @Published public private(set) var copyInMs: Double = 0
    @Published public private(set) var compositeMs: Double = 0
    @Published public private(set) var copyOutMs: Double = 0
    @Published public private(set) var providerLabel: String = "—"
    @Published public private(set) var engineLabel: String = "—"
    @Published public private(set) var resolutionLabel: String = "—"
    /// Drives the HUD visibility. Set from the Settings preference via the
    /// adapter; the HUD view returns `EmptyView` when this is `false`.
    @Published public private(set) var isVisible: Bool = false

    // MARK: - Internals

    private let windowSize = 30
    private var transformSamples: [Double] = []
    private var visionSamples: [Double] = []
    private var copyInSamples: [Double] = []
    private var compositeSamples: [Double] = []
    private var copyOutSamples: [Double] = []
    private var frameTimestamps: [CFAbsoluteTime] = []
    private var lastUIPushAt: CFAbsoluteTime = 0
    private let uiPushIntervalSeconds: CFAbsoluteTime = 0.2  // 5 Hz HUD refresh
    private let lock = NSLock()

    public init() {}

    /// Update the provider label shown in the HUD. Called from the routing layer
    /// when a transformer is constructed / cleared.
    public func setProviderLabel(_ label: String) {
        Task { @MainActor in
            self.providerLabel = label
        }
    }

    /// Update the engine label. For Apple Vision this is an informed guess
    /// ("ANE") rather than runtime-verified — CoreML doesn't expose which
    /// compute unit it chose. Use Instruments → Core ML for definitive proof.
    public func setEngineLabel(_ label: String) {
        Task { @MainActor in
            self.engineLabel = label
        }
    }

    /// Update the resolution label. Pushed from inside the Apple Vision
    /// transformer; for the Vonage path we have no in-line resolution signal,
    /// so it stays at the last known value (or "—" after a `reset`).
    public func setResolution(width: Int, height: Int) {
        Task { @MainActor in
            self.resolutionLabel = "\(width)x\(height)"
        }
    }

    /// Toggle HUD visibility. Wired up from the Settings preference adapter
    /// (`performanceHUDEnabled`).
    public func setVisible(_ visible: Bool) {
        Task { @MainActor in
            self.isVisible = visible
        }
    }

    /// Record just one frame's arrival — for paths where we have no timing
    /// signal (e.g. the Vonage path, where the blur is internal to their SDK).
    /// Only updates ``framesPerSecond``; leaves transform/vision timings untouched.
    public func recordFrame() {
        lock.lock()
        let now = CFAbsoluteTimeGetCurrent()
        frameTimestamps.append(now)
        while !frameTimestamps.isEmpty && now - frameTimestamps[0] > 1.0 {
            frameTimestamps.removeFirst()
        }
        let fps = Double(frameTimestamps.count)
        let shouldPush = now - lastUIPushAt > uiPushIntervalSeconds
        if shouldPush { lastUIPushAt = now }
        lock.unlock()

        guard shouldPush else { return }
        Task { @MainActor in
            self.framesPerSecond = fps
        }
    }

    /// Record one frame's pipeline timings.
    ///
    /// Safe to call from any thread. UI publication is throttled to ~5 Hz on main.
    public func record(
        transformMs: Double,
        visionMs: Double,
        copyInMs: Double = 0,
        compositeMs: Double = 0,
        copyOutMs: Double = 0
    ) {
        lock.lock()

        transformSamples.append(transformMs)
        if transformSamples.count > windowSize { transformSamples.removeFirst() }

        visionSamples.append(visionMs)
        if visionSamples.count > windowSize { visionSamples.removeFirst() }

        copyInSamples.append(copyInMs)
        if copyInSamples.count > windowSize { copyInSamples.removeFirst() }

        compositeSamples.append(compositeMs)
        if compositeSamples.count > windowSize { compositeSamples.removeFirst() }

        copyOutSamples.append(copyOutMs)
        if copyOutSamples.count > windowSize { copyOutSamples.removeFirst() }

        let now = CFAbsoluteTimeGetCurrent()
        frameTimestamps.append(now)
        while !frameTimestamps.isEmpty && now - frameTimestamps[0] > 1.0 {
            frameTimestamps.removeFirst()
        }

        let avgTransform = transformSamples.reduce(0, +) / Double(transformSamples.count)
        let avgVision = visionSamples.reduce(0, +) / Double(visionSamples.count)
        let avgCopyIn = copyInSamples.reduce(0, +) / Double(copyInSamples.count)
        let avgComposite = compositeSamples.reduce(0, +) / Double(compositeSamples.count)
        let avgCopyOut = copyOutSamples.reduce(0, +) / Double(copyOutSamples.count)
        let fps = Double(frameTimestamps.count)
        let shouldPush = now - lastUIPushAt > uiPushIntervalSeconds
        if shouldPush { lastUIPushAt = now }

        lock.unlock()

        guard shouldPush else { return }
        Task { @MainActor in
            self.transformMs = avgTransform
            self.visionMs = avgVision
            self.copyInMs = avgCopyIn
            self.compositeMs = avgComposite
            self.copyOutMs = avgCopyOut
            self.framesPerSecond = fps
        }
    }

    /// Clear all counters. Call when switching providers so stale samples don't
    /// linger in the rolling window.
    public func reset() {
        lock.lock()
        transformSamples.removeAll()
        visionSamples.removeAll()
        copyInSamples.removeAll()
        compositeSamples.removeAll()
        copyOutSamples.removeAll()
        frameTimestamps.removeAll()
        lock.unlock()

        Task { @MainActor in
            self.transformMs = 0
            self.visionMs = 0
            self.copyInMs = 0
            self.compositeMs = 0
            self.copyOutMs = 0
            self.framesPerSecond = 0
            self.resolutionLabel = "—"
        }
    }
}
