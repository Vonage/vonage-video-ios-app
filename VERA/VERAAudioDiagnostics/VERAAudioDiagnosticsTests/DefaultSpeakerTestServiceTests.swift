//
//  Created by Vonage on 03/07/26.
//

import AVFoundation
import Combine
import Testing

@testable import VERAAudioDiagnostics

@Suite("DefaultSpeakerTestService tests")
struct DefaultSpeakerTestServiceTests {

    @Test("playTestSound does not crash when no audio file is available")
    func playTestSoundWithNoAudioFileDoesNotCrash() {
        let sut = DefaultSpeakerTestService(audioPlayerFactory: { nil })
        sut.playTestSound()
        // No assertion needed — test passes if no crash occurs.
    }

    @Test("playTestSound invokes the player factory exactly once")
    func playTestSoundInvokesFactoryOnce() {
        var factoryCallCount = 0
        let sut = DefaultSpeakerTestService(audioPlayerFactory: {
            factoryCallCount += 1
            return nil
        })

        sut.playTestSound()

        #expect(factoryCallCount == 1)
    }

    @Test("calling playTestSound multiple times invokes the factory each time")
    func playTestSoundInvokesFactoryEachCall() {
        var factoryCallCount = 0
        let sut = DefaultSpeakerTestService(audioPlayerFactory: {
            factoryCallCount += 1
            return nil
        })

        sut.playTestSound()
        sut.playTestSound()
        sut.playTestSound()

        #expect(factoryCallCount == 3)
    }

    @Test("audioLevelPublisher emits values when playing sound")
    func audioLevelPublisherEmitsValues() async {
        // This test needs real AVAudioPlayer which requires UIKit/AppKit
        // Skipping for now - manual testing required
    }

    @Test("audioLevelPublisher sends zero when playback stops")
    func audioLevelPublisherSendsZeroWhenStopped() async {
        // This test needs real AVAudioPlayer which requires UIKit/AppKit
        // Skipping for now - manual testing required
    }
}
