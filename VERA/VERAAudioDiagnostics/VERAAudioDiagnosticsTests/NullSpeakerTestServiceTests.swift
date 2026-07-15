//
//  Created by Vonage on 07/07/26.
//

import Combine
import Testing

@testable import VERAAudioDiagnostics

@Suite("NullSpeakerTestService tests")
struct NullSpeakerTestServiceTests {

    @Test("playTestSound does not crash")
    func playTestSoundDoesNotCrash() {
        let sut = NullSpeakerTestService()
        sut.playTestSound()
        // Test passes if no crash occurs
    }

    @Test("stopTestSound does not crash")
    func stopTestSoundDoesNotCrash() {
        let sut = NullSpeakerTestService()
        sut.stopTestSound()
        // Test passes if no crash occurs
    }

    @Test("audioLevelPublisher never emits values")
    func audioLevelPublisherNeverEmits() async {
        let sut = NullSpeakerTestService()
        var receivedValues: [Float] = []

        let cancellable = sut.audioLevelPublisher
            .sink { value in
                receivedValues.append(value)
            }

        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(receivedValues.isEmpty)

        cancellable.cancel()
    }

    @Test("can be initialized")
    func canBeInitialized() {
        let sut = NullSpeakerTestService()
        #expect(sut.audioLevelPublisher is AnyPublisher<Float, Never>)
    }

    @Test("multiple calls to playTestSound do not crash")
    func multiplePlayTestSoundCallsDoNotCrash() {
        let sut = NullSpeakerTestService()
        sut.playTestSound()
        sut.playTestSound()
        sut.playTestSound()
        // Test passes if no crash occurs
    }

    @Test("multiple calls to stopTestSound do not crash")
    func multipleStopTestSoundCallsDoNotCrash() {
        let sut = NullSpeakerTestService()
        sut.stopTestSound()
        sut.stopTestSound()
        sut.stopTestSound()
        // Test passes if no crash occurs
    }

    // MARK: - Audio Route Observation Tests

    @Test("startObservingAudioRoutes does not crash")
    func startObservingAudioRoutesDoesNotCrash() {
        let sut = NullSpeakerTestService()
        sut.startObservingAudioRoutes()
        // Test passes if no crash occurs
    }

    @Test("stopObservingAudioRoutes does not crash")
    func stopObservingAudioRoutesDoesNotCrash() {
        let sut = NullSpeakerTestService()
        sut.stopObservingAudioRoutes()
        // Test passes if no crash occurs
    }

    @Test("startObservingAudioRoutes and stopObservingAudioRoutes can be called repeatedly")
    func audioRoutesObservationCanBeCalledRepeatedly() {
        let sut = NullSpeakerTestService()
        for _ in 0..<5 {
            sut.startObservingAudioRoutes()
            sut.stopObservingAudioRoutes()
        }
        // Test passes if no crash occurs
    }
}
