//
//  Created by Vonage on 03/07/26.
//

import Combine
import Foundation

/// A service that plays a short test tone through the current audio output.
///
/// Implement this protocol to provide speaker testing functionality
/// that can be verified against the device's active audio route.
public protocol SpeakerTestService: Sendable {
    /// Plays a short test tone through the current audio output route.
    func playTestSound()

    /// Stops the currently playing test sound.
    func stopTestSound()

    /// Starts listening for audio route changes.
    ///
    /// Call this to enable automatic playback restart when the audio output device changes.
    func startObservingAudioRoutes()

    /// Stops listening for audio route changes.
    func stopObservingAudioRoutes()

    /// Publisher that emits audio level updates (0.0 to 1.0) while playing test sound.
    var audioLevelPublisher: AnyPublisher<Float, Never> { get }
}
