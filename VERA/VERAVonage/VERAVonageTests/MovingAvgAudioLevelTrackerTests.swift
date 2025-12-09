//
//  Created by Vonage on 12/8/25.
//

import Foundation
import Testing
import VERAVonage

@Suite("MovingAvgAudioLevelTracker Tests")
struct MovingAvgAudioLevelTrackerTests {

    // MARK: - Basic Functionality Tests

    @Test("Initial state should return zero values")
    func testInitialState() {
        let tracker = makeSUT()
        let result = tracker.track(0.0)

        #expect(result.movingAvg == 0.0)
        #expect(result.logMovingAvg >= 0.0)
    }

    @Test("Single audio level tracking")
    func testSingleAudioLevelTracking() {
        let tracker = makeSUT()

        // Test silence level
        let silenceResult = tracker.track(0.0003662221)
        #expect(silenceResult.movingAvg == 0.0003662221)
        #expect(silenceResult.logMovingAvg >= 0.0)

        // Test speaking level
        let speakingResult = tracker.track(0.5015107)
        #expect(speakingResult.movingAvg == 0.5015107)
        #expect(speakingResult.logMovingAvg > silenceResult.logMovingAvg)
    }

    @Test("Audio level increases should update moving average immediately")
    func testImmediateIncrease() {
        let tracker = makeSUT()

        // Start with low level
        let lowResult = tracker.track(0.0003662221)

        // Jump to high level - should update immediately
        let highResult = tracker.track(1.0)

        #expect(highResult.movingAvg == 1.0)
        #expect(highResult.logMovingAvg > lowResult.logMovingAvg)
    }

    @Test("Audio level decreases should use smoothing")
    func testSmoothingOnDecrease() {
        let tracker = makeSUT()

        // Start with high level
        let highResult = tracker.track(1.0)
        #expect(highResult.movingAvg == 1.0)

        // Drop to low level - should use smoothing (0.7 * 1.0 + 0.3 * 0.0003662221)
        let lowResult = tracker.track(0.0003662221)
        let expectedMovingAvg: Float = 0.7 * 1.0 + 0.3 * 0.0003662221

        #expect(fabsf(lowResult.movingAvg - expectedMovingAvg) < 0.001)
        #expect(lowResult.movingAvg > 0.0003662221)  // Should be higher than current level
        #expect(lowResult.movingAvg < 1.0)  // But lower than previous level
    }

    // MARK: - Real Audio Sequence Tests

    @Test("Complete audio sequence from silence to loud speaking")
    func testRealAudioSequence() {
        let tracker = makeSUT()

        let audioSequence: [Float] = [
            // Silence phase
            0.0003662221, 0.0003662221, 0.0003662221,
            0.00048829615, 0.00048829615,
            0.0006408887, 0.0006408887,

            // Starting to speak
            0.027527696, 0.027527696,
            0.054109316, 0.054109316,
            0.18375194, 0.18375194, 0.18375194,

            // Medium volume
            0.06488235, 0.10660116, 0.10660116,
            0.5015107, 0.5015107, 0.5015107,
            0.51185644, 0.51185644,

            // Loud speaking
            1.0, 1.0,

            // Decreasing volume
            0.24997711, 0.24997711,
            0.06247139, 0.06247139,
            0.015594958, 0.015594958,
            0.0038758507, 0.0038758507,

            // Speaking again
            0.32609028, 0.32609028,
            0.6621906, 0.6621906,
            1.0, 1.0, 1.0, 1.0,
        ]

        let results = trackSequence(tracker, levels: audioSequence)

        // Verify sequence properties
        #expect(results.count == audioSequence.count)

        // All logMovingAvg values should be between 0 and 1
        for result in results {
            #expect(result.logMovingAvg >= 0.0)
            #expect(result.logMovingAvg <= 1.0)
        }

        // Moving average should generally follow the trend
        let silenceAvg = results[2].movingAvg  // After 3 silence samples
        let loudAvg = results[22].movingAvg  // During loud speaking
        let quietAvg = results[30].movingAvg  // After decreasing

        #expect(silenceAvg < loudAvg)
        #expect(quietAvg < loudAvg)
    }

    @Test("Log moving average progression during speaking")
    func testLogMovingAverageProgression() {
        let tracker = makeSUT()

        // Test specific progression: silence -> speaking -> loud
        let progressionLevels: [Float] = [
            0.0003662221,  // Silence
            0.18375194,  // Starting to speak
            0.5015107,  // Speaking
            1.0,  // Loud speaking
        ]

        let results = trackSequence(tracker, levels: progressionLevels)

        // Log moving average should increase with audio level
        for i in 1..<results.count {
            #expect(
                results[i].logMovingAvg >= results[i - 1].logMovingAvg,
                "Log moving average should not decrease when audio level increases")
        }
    }

    // MARK: - Edge Cases Tests

    @Test("Zero audio level handling")
    func testZeroAudioLevel() {
        let tracker = makeSUT()

        let result = tracker.track(0.0)

        #expect(result.movingAvg == 0.0)
        #expect(result.logMovingAvg >= 0.0)
    }

    @Test("Maximum audio level handling")
    func testMaximumAudioLevel() {
        let tracker = makeSUT()

        let result = tracker.track(1.0)

        #expect(result.movingAvg == 1.0)
        #expect(result.logMovingAvg <= 1.0)
    }

    @Test("Rapid level changes")
    func testRapidLevelChanges() {
        let tracker = makeSUT()

        let rapidChanges: [Float] = [0.0, 1.0, 0.0, 1.0, 0.5]
        let results = trackSequence(tracker, levels: rapidChanges)

        // Verify no NaN or infinite values
        for result in results {
            #expect(result.movingAvg.isFinite)
            #expect(result.logMovingAvg.isFinite)
            #expect(!result.movingAvg.isNaN)
            #expect(!result.logMovingAvg.isNaN)
        }
    }

    // MARK: - Smoothing Factor Tests

    @Test("Smoothing behavior verification")
    func testSmoothingBehavior() {
        let tracker = makeSUT()

        // Set high level first
        _ = tracker.track(1.0)

        // Then track a much lower level multiple times
        let lowLevel: Float = 0.1
        var previousMovingAvg: Float = 1.0

        for _ in 0..<5 {
            let result = tracker.track(lowLevel)

            // Moving average should decrease but not reach the low level immediately
            #expect(result.movingAvg < previousMovingAvg)
            #expect(result.movingAvg > lowLevel)

            previousMovingAvg = result.movingAvg
        }
    }

    // MARK: - Boundary Value Tests

    @Test("Very small audio levels")
    func testVerySmallAudioLevels() {
        let tracker = makeSUT()

        let verySmallLevels: [Float] = [
            0.0001, 0.0003662221, 0.00048829615, 0.0006408887,
        ]

        let results = trackSequence(tracker, levels: verySmallLevels)

        for result in results {
            #expect(result.movingAvg >= 0.0)
            #expect(result.logMovingAvg >= 0.0)
            #expect(result.logMovingAvg <= 1.0)
        }
    }

    @Test("Consistent audio level behavior")
    func testConsistentAudioLevel() {
        let tracker = makeSUT()

        let consistentLevel: Float = 0.5
        let results = Array(0..<10).map { _ in tracker.track(consistentLevel) }

        // All results should be the same since level doesn't change
        for result in results {
            #expect(fabsf(result.movingAvg - consistentLevel) < 0.001)
        }
    }

    // MARK: - Performance Characteristics Tests

    @Test("Moving average convergence")
    func testMovingAverageConvergence() {
        let tracker = makeSUT()

        // Start with high level
        _ = tracker.track(1.0)

        // Apply consistent low level and verify convergence
        let targetLevel: Float = 0.2
        var result = tracker.track(targetLevel)

        // After many iterations, moving average should approach target level
        for _ in 0..<50 {
            result = tracker.track(targetLevel)
        }

        // Should be close to target level but due to smoothing, not exactly equal
        #expect(fabsf(result.movingAvg - targetLevel) < 0.1)
        #expect(result.movingAvg > targetLevel * 0.8)  // Within reasonable range
    }

    // MARK: - Test Helpers

    private func makeSUT() -> MovingAvgAudioLevelTracker {
        return MovingAvgAudioLevelTracker()
    }

    private func trackSequence(
        _ tracker: MovingAvgAudioLevelTracker,
        levels: [Float]
    ) -> [(movingAvg: Float, logMovingAvg: Float)] {
        return levels.map { tracker.track($0) }
    }
}
