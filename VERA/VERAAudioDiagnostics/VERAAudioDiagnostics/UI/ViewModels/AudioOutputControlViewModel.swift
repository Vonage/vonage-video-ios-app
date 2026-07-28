//
//  Created by Vonage on 06/07/26.
//

import Combine
import Foundation

/// ViewModel dedicated to the audio output control panel.
///
/// Manages speaker testing and real-time audio level monitoring.
/// Designed to be portable and reusable across different contexts (Settings, Waiting Room, etc.).
@MainActor
public final class AudioOutputControlViewModel: ObservableObject {

    // MARK: - Published State

    /// Current audio output level (0.0 to 1.0).
    /// Updated in real-time when testing audio output.
    @Published public var currentAudioLevel: Float = 0.0

    /// Whether audio is currently playing.
    @Published public var isPlaying: Bool = false

    // MARK: - Dependencies

    private let speakerTestService: SpeakerTestService
    private var audioLevelCancellable: AnyCancellable?

    // MARK: - Initialization

    /// Creates a new audio output control view model.
    ///
    /// - Parameter speakerTestService: Service responsible for playing test tones and monitoring audio levels.
    public init(speakerTestService: SpeakerTestService) {
        self.speakerTestService = speakerTestService
    }

    /// Sets up the audio level subscription. Should be called from the MainActor.
    @MainActor
    private func setupAudioLevelSubscription() {
        guard audioLevelCancellable == nil else { return }
        audioLevelCancellable = speakerTestService.audioLevelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.currentAudioLevel = level
            }
    }

    // MARK: - Actions

    /// Toggles audio playback: plays if stopped, stops if playing.
    @MainActor
    public func togglePlayback() {
        if isPlaying {
            stopSpeaker()
        } else {
            testSpeaker()
        }
    }

    /// Plays a short test tone through the current audio output route.
    /// Audio levels are automatically published via `currentAudioLevel`.
    @MainActor
    public func testSpeaker() {
        setupAudioLevelSubscription()
        speakerTestService.playTestSound()
        isPlaying = true
    }

    /// Stops the currently playing test sound.
    @MainActor
    public func stopSpeaker() {
        speakerTestService.stopTestSound()
        isPlaying = false
        currentAudioLevel = 0.0
    }
}
