//
//  Created by Vonage on 07/07/26.
//

import Combine
import Foundation
import VERAAudioDiagnostics

/// Mock implementation of ``SpeakerTestService`` for snapshot testing.
///
/// This mock provides controllable audio level streams without requiring actual audio hardware,
/// making it ideal for snapshot tests where visual appearance is validated.
@MainActor
final class MockSpeakerTestService: SpeakerTestService {

    // MARK: - Properties

    private let audioLevelSubject = PassthroughSubject<Float, Never>()

    var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }

    private(set) var playTestSoundCallCount = 0
    private(set) var stopTestSoundCallCount = 0

    // MARK: - Control Methods

    /// Simulates playing a test sound.
    ///
    /// Increments the call counter but does not emit audio levels automatically.
    /// Use ``emitAudioLevel(_:)`` to simulate audio playback.
    func playTestSound() {
        playTestSoundCallCount += 1
    }

    /// Simulates stopping the test sound.
    ///
    /// Increments the call counter and emits a zero audio level.
    func stopTestSound() {
        stopTestSoundCallCount += 1
        audioLevelSubject.send(0.0)
    }

    /// Simulates stopping audio route observation.
    func startObservingAudioRoutes() {
        // Not used for snapthot testing
    }

    /// Simulates starting audio route observation.
    func stopObservingAudioRoutes() {
        // Not used for snapthot testing
    }

    // MARK: - Test Helpers

    /// Emits a simulated audio level value.
    ///
    /// - Parameter level: Audio level between 0.0 (silent) and 1.0 (maximum).
    func emitAudioLevel(_ level: Float) {
        audioLevelSubject.send(level)
    }

    /// Emits a sequence of audio levels to simulate realistic audio playback.
    ///
    /// - Parameter levels: Array of audio level values to emit in sequence.
    func emitAudioLevels(_ levels: [Float]) {
        for level in levels {
            audioLevelSubject.send(level)
        }
    }
}
