//
//  Created by Vonage on 18/6/26.
//

import Combine
import Foundation
import Testing

@testable import VERAMeetingRoom

@Suite("SpeakingWhileMutedDetector tests")
struct SpeakingWhileMutedDetectorTests {

    // MARK: - Helpers

    private func makeSUT(
        isMicEnabled: CurrentValueSubject<Bool, Never> = .init(true),
        audioLevel: CurrentValueSubject<Float, Never> = .init(0)
    ) -> (
        sut: SpeakingWhileMutedDetector,
        micSubject: CurrentValueSubject<Bool, Never>,
        levelSubject: CurrentValueSubject<Float, Never>
    ) {
        let sut = SpeakingWhileMutedDetector(
            isMicEnabled: isMicEnabled.eraseToAnyPublisher(),
            audioLevel: audioLevel.eraseToAnyPublisher()
        )
        return (sut, isMicEnabled, audioLevel)
    }

    private func collectValues(
        from publisher: AnyPublisher<Bool, Never>,
        while block: () -> Void
    ) -> [Bool] {
        var values: [Bool] = []
        let cancellable = publisher.sink { values.append($0) }
        block()
        cancellable.cancel()
        return values
    }

    // MARK: - Tests

    @Test("No emission when mic is enabled regardless of audio level")
    func noDetectionWhenMicIsEnabled() {
        let micSubject = CurrentValueSubject<Bool, Never>(true)
        let levelSubject = CurrentValueSubject<Float, Never>(0)
        let (sut, _, _) = makeSUT(isMicEnabled: micSubject, audioLevel: levelSubject)

        let values = collectValues(from: sut.isSpeakingWhileMuted) {
            levelSubject.value = 0.5
            levelSubject.value = 0.8
            levelSubject.value = 1.0
        }

        #expect(values.allSatisfy { !$0 })
    }

    @Test("No detection when muted but audio level is below threshold")
    func noDetectionWhenMutedButAudioLevelBelowThreshold() {
        let micSubject = CurrentValueSubject<Bool, Never>(false)
        let levelSubject = CurrentValueSubject<Float, Never>(0)
        let (sut, _, _) = makeSUT(isMicEnabled: micSubject, audioLevel: levelSubject)

        let values = collectValues(from: sut.isSpeakingWhileMuted) {
            levelSubject.value = 0.05
            levelSubject.value = 0.09
            levelSubject.value = 0.0
        }

        #expect(values.allSatisfy { !$0 })
    }

    @Test("Triggers true after triggerThreshold consecutive loud-while-muted samples")
    func triggersAfterConsecutiveLoudWhileMutedSamples() {
        let micSubject = CurrentValueSubject<Bool, Never>(false)
        let levelSubject = CurrentValueSubject<Float, Never>(0)
        let (sut, _, _) = makeSUT(isMicEnabled: micSubject, audioLevel: levelSubject)

        var values: [Bool] = []
        let cancellable = sut.isSpeakingWhileMuted.sink { values.append($0) }

        // Send triggerThreshold - 1 loud samples — should not trigger yet
        for _ in 0..<(SpeakingWhileMutedDetector.triggerThreshold - 1) {
            levelSubject.value = 0.5
        }
        #expect(values.allSatisfy { !$0 })

        // The triggerThreshold-th sample should trigger
        levelSubject.value = 0.5
        #expect(values.last == true)

        cancellable.cancel()
    }

    @Test("Emits false when audio drops after detection")
    func emitsFalseWhenAudioDropsAfterDetection() {
        let micSubject = CurrentValueSubject<Bool, Never>(false)
        let levelSubject = CurrentValueSubject<Float, Never>(0)
        let (sut, _, _) = makeSUT(isMicEnabled: micSubject, audioLevel: levelSubject)

        var values: [Bool] = []
        let cancellable = sut.isSpeakingWhileMuted.sink { values.append($0) }

        // Trigger detection
        for _ in 0..<SpeakingWhileMutedDetector.triggerThreshold {
            levelSubject.value = 0.5
        }
        #expect(values.last == true)

        // Drop audio — should go back to false
        levelSubject.value = 0.0
        #expect(values.last == false)

        cancellable.cancel()
    }

    @Test("Re-triggers after a second speaking episode")
    func retriggersAfterSecondSpeakingEpisode() {
        let micSubject = CurrentValueSubject<Bool, Never>(false)
        let levelSubject = CurrentValueSubject<Float, Never>(0)
        let (sut, _, _) = makeSUT(isMicEnabled: micSubject, audioLevel: levelSubject)

        var values: [Bool] = []
        let cancellable = sut.isSpeakingWhileMuted.sink { values.append($0) }

        // First episode
        for _ in 0..<SpeakingWhileMutedDetector.triggerThreshold {
            levelSubject.value = 0.5
        }
        #expect(values.last == true)

        // Silence — resets
        levelSubject.value = 0.0
        #expect(values.last == false)

        // Second episode
        for _ in 0..<SpeakingWhileMutedDetector.triggerThreshold {
            levelSubject.value = 0.5
        }
        #expect(values.last == true)

        cancellable.cancel()
    }

    @Test("No detection when mic toggles back on while loud")
    func noDetectionWhenMicTogglesBackOn() {
        let micSubject = CurrentValueSubject<Bool, Never>(false)
        let levelSubject = CurrentValueSubject<Float, Never>(0)
        let (sut, _, _) = makeSUT(isMicEnabled: micSubject, audioLevel: levelSubject)

        var values: [Bool] = []
        let cancellable = sut.isSpeakingWhileMuted.sink { values.append($0) }

        // Start speaking while muted — but re-enable mic before reaching threshold
        levelSubject.value = 0.5
        micSubject.value = true
        levelSubject.value = 0.5

        #expect(values.allSatisfy { !$0 })

        cancellable.cancel()
    }
}
