//
//  Created by Vonage on 03/07/26.
//

import AVFoundation
import VERADomain

/// Default implementation of ``SpeakerTestService`` that plays a short tone
/// through the device's current audio output route using `AVAudioPlayer`.
///
/// Pass a custom `audioPlayerFactory` in tests to avoid requiring real audio hardware.
public final class DefaultSpeakerTestService: SpeakerTestService, @unchecked Sendable {

    private let audioPlayerFactory: () -> AVAudioPlayer?
    private var player: AVAudioPlayer?

    /// Creates a service that loads `SpeakerTestTone.aiff` from the given bundle.
    ///
    /// - Parameter bundle: The bundle to search for the audio asset. Defaults to `VERACore`'s bundle.
    public convenience init(bundle: Bundle = Bundle(for: DefaultSpeakerTestService.self)) {
        self.init {
            guard let url = bundle.url(forResource: "SpeakerTestTone", withExtension: "aiff") else {
                return nil
            }
            return try? AVAudioPlayer(contentsOf: url)
        }
    }

    /// Creates a service with a custom audio player factory.
    ///
    /// - Parameter audioPlayerFactory: Closure that returns the `AVAudioPlayer` to use.
    ///   Inject a test double here during unit testing.
    public init(audioPlayerFactory: @escaping () -> AVAudioPlayer?) {
        self.audioPlayerFactory = audioPlayerFactory
    }

    public func playTestSound() {
        player = audioPlayerFactory()
        player?.prepareToPlay()
        player?.play()
    }
}
