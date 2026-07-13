//
//  Created by Vonage on 13/07/2026.
//

import Combine

@testable import VERAAudioDiagnostics

@MainActor
public final class MockSpeakerTestService: SpeakerTestService {
    private let audioLevelSubject = PassthroughSubject<Float, Never>()

    public var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }

    private(set) var playTestSoundCallCount = 0
    private(set) var stopTestSoundCallCount = 0

    public func playTestSound() {
        playTestSoundCallCount += 1
    }

    public func stopTestSound() {
        stopTestSoundCallCount += 1
        audioLevelSubject.send(0.0)
    }

    func emitAudioLevel(_ level: Float) {
        audioLevelSubject.send(level)
    }
}
