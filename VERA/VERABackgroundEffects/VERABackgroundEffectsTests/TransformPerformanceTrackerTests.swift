//
//  Created by Vonage on 11/5/26.
//

import Foundation
import Testing

@testable import VERABackgroundEffects

@Suite("TransformPerformanceTracker tests")
@MainActor
struct TransformPerformanceTrackerTests {

    @Test
    func initialStateIsClean() {
        let sut = TransformPerformanceTracker()

        #expect(sut.framesPerSecond == 0)
        #expect(sut.transformMs == 0)
        #expect(sut.visionMs == 0)
        #expect(sut.copyInMs == 0)
        #expect(sut.compositeMs == 0)
        #expect(sut.copyOutMs == 0)
        #expect(sut.providerLabel == "—")
        #expect(sut.engineLabel == "—")
        #expect(sut.resolutionLabel == "—")
        #expect(sut.isVisible == false)
    }

    @Test
    func setProviderLabelUpdatesPublishedValue() async {
        let sut = TransformPerformanceTracker()

        sut.setProviderLabel("Apple Vision")
        await waitForMainHop()

        #expect(sut.providerLabel == "Apple Vision")
    }

    @Test
    func setEngineLabelUpdatesPublishedValue() async {
        let sut = TransformPerformanceTracker()

        sut.setEngineLabel("ANE")
        await waitForMainHop()

        #expect(sut.engineLabel == "ANE")
    }

    @Test
    func setVisibleUpdatesPublishedValue() async {
        let sut = TransformPerformanceTracker()

        sut.setVisible(true)
        await waitForMainHop()

        #expect(sut.isVisible == true)

        sut.setVisible(false)
        await waitForMainHop()

        #expect(sut.isVisible == false)
    }

    @Test
    func setResolutionUpdatesLabel() async {
        let sut = TransformPerformanceTracker()

        sut.setResolution(width: 1920, height: 1080)
        await waitForMainHop()

        #expect(sut.resolutionLabel == "1920x1080")
    }

    @Test
    func setResolutionWithSameValueIsIdempotent() async {
        // Documents the per-frame optimisation: repeated calls with the same
        // value don't dispatch a new `Task { @MainActor }`. We verify by
        // observing that the published label is still the first value after
        // multiple identical calls (which would be true either way), but more
        // importantly that calling N times doesn't trip any assertion or
        // produce a wrong label.
        let sut = TransformPerformanceTracker()

        sut.setResolution(width: 640, height: 480)
        sut.setResolution(width: 640, height: 480)
        sut.setResolution(width: 640, height: 480)
        await waitForMainHop()

        #expect(sut.resolutionLabel == "640x480")
    }

    @Test
    func setResolutionWithChangedValueUpdatesLabel() async {
        let sut = TransformPerformanceTracker()

        sut.setResolution(width: 640, height: 480)
        await waitForMainHop()
        #expect(sut.resolutionLabel == "640x480")

        sut.setResolution(width: 1280, height: 720)
        await waitForMainHop()
        #expect(sut.resolutionLabel == "1280x720")
    }

    @Test
    func recordFramePushesFpsAfterThrottle() async throws {
        let sut = TransformPerformanceTracker()

        // First frame arrives — published value gets pushed on the first call
        // (no `lastUIPushAt` yet), so we can verify the FPS computation took place.
        sut.recordFrame()
        await waitForMainHop()
        #expect(sut.framesPerSecond > 0)
    }

    @Test
    func recordSamplesRollIntoAverages() async throws {
        let sut = TransformPerformanceTracker()

        // Single sample → average equals the sample itself once the UI throttle
        // allows a push.
        sut.record(transformMs: 8.0, visionMs: 4.0, copyInMs: 1.0, compositeMs: 2.0, copyOutMs: 1.0)
        await waitForMainHop()

        #expect(sut.transformMs == 8.0)
        #expect(sut.visionMs == 4.0)
        #expect(sut.copyInMs == 1.0)
        #expect(sut.compositeMs == 2.0)
        #expect(sut.copyOutMs == 1.0)
    }

    @Test
    func resetClearsTimingsAndResolution() async {
        // `reset()` clears the rolling timing samples, fps, and the resolution
        // label — but intentionally leaves provider/engine labels alone so the
        // caller in `setBackgroundBlur` can immediately set them to the new
        // provider's labels (or "off" / "—") without an extra hop.
        let sut = TransformPerformanceTracker()

        sut.setProviderLabel("Vonage")
        sut.setEngineLabel("CPU")
        sut.setResolution(width: 1280, height: 720)
        sut.record(transformMs: 10, visionMs: 5)
        await waitForMainHop()

        sut.reset()
        await waitForMainHop()

        #expect(sut.transformMs == 0)
        #expect(sut.visionMs == 0)
        #expect(sut.copyInMs == 0)
        #expect(sut.compositeMs == 0)
        #expect(sut.copyOutMs == 0)
        #expect(sut.framesPerSecond == 0)
        #expect(sut.resolutionLabel == "—")

        // Provider/engine intentionally preserved across reset.
        #expect(sut.providerLabel == "Vonage")
        #expect(sut.engineLabel == "CPU")
    }

    @Test
    func sharedSingletonReturnsSameInstance() {
        // Exercises the static `shared` declaration; routing/adapter code uses
        // it by reference, so the identity guarantee is load-bearing.
        let a = TransformPerformanceTracker.shared
        let b = TransformPerformanceTracker.shared
        #expect(a === b)
    }

    // Yields long enough for the `Task { @MainActor in ... }` hops inside the
    // tracker's setters to land. A short sleep is more reliable than
    // `Task.yield()` for cross-thread dispatch in Swift Testing.
    private func waitForMainHop() async {
        try? await Task.sleep(nanoseconds: 50_000_000)  // 50 ms
    }
}
