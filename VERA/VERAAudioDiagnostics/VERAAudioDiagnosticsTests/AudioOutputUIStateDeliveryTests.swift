import Combine
import Foundation
import Testing

@testable import VERAAudioDiagnostics

@MainActor
@Suite("Audio output UI-owned publisher delivery")
struct AudioOutputUIStateDeliveryTests {
    @Test("Background audio levels update UI state, and stopping clears the level")
    func backgroundAudioLevelsReachUIState() async {
        let sut = AudioOutputControlViewModel(speakerTestService: BackgroundSpeakerTestService())
        sut.testSpeaker()

        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while ContinuousClock.now < deadline, sut.currentAudioLevel != 0.75 {
            try? await Task.sleep(for: .milliseconds(10))
        }

        #expect(sut.currentAudioLevel == 0.75)
        #expect(sut.isPlaying)
        sut.stopSpeaker()
        #expect(sut.currentAudioLevel == 0)
        #expect(!sut.isPlaying)
    }
}

private final class BackgroundSpeakerTestService: SpeakerTestService {
    private let queue = DispatchQueue(label: "audio-output-ui-test-delivery")

    var audioLevelPublisher: AnyPublisher<Float, Never> {
        [Float(0.25), Float(0.75)].publisher
            .subscribe(on: queue)
            .map { @Sendable level in
                #expect(!Thread.isMainThread)
                return level
            }
            .eraseToAnyPublisher()
    }

    func playTestSound() {}
    func stopTestSound() {}
    func startObservingAudioRoutes() {}
    func stopObservingAudioRoutes() {}
}
