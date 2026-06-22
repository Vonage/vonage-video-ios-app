//
//  Created by Vonage on 18/6/26.
//

import Combine
import Foundation

/// Detects when the local user is speaking while their microphone is muted.
///
/// Combines the microphone mute state with the publisher's real-time audio level.
/// Uses consecutive-sample hysteresis to avoid flickering: the output transitions
/// to `true` only after ``triggerThreshold`` consecutive loud-while-muted samples,
/// and resets to `false` as soon as the condition is no longer met.
///
/// ## Usage
/// ```swift
/// let detector = SpeakingWhileMutedDetector(
///     isMicEnabled: call.statePublisher.map(\.isPublishingAudio).eraseToAnyPublisher(),
///     audioLevel: call.publisherAudioLevelPublisher
/// )
/// detector.isSpeakingWhileMuted
///     .filter { $0 }
///     .sink { _ in showMutedWarning() }
///     .store(in: &cancellables)
/// ```
public final class SpeakingWhileMutedDetector {

    // MARK: - Constants

    /// Minimum audio level considered significant enough to constitute "speaking".
    /// Matches the Android implementation and the existing `ActiveSpeakerTracker` minimum.
    public static let audioLevelThreshold: Float = 0.1

    /// Number of consecutive loud-while-muted samples required before emitting `true`.
    /// Prevents flickering on brief noise bursts.
    public static let triggerThreshold: Int = 3

    private let isMicEnabled: AnyPublisher<Bool, Never>
    private let audioLevel: AnyPublisher<Float, Never>

    // MARK: - Output

    /// Emits `true` when the user is speaking while muted, `false` otherwise.
    ///
    /// Distinct consecutive values only — subscribers will not receive repeated emissions
    /// of the same boolean.
    public lazy var isSpeakingWhileMuted: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest(isMicEnabled, audioLevel)
            .scan(DetectionState()) { state, pair in
                let (micEnabled, level) = pair
                let isLoudWhileMuted = !micEnabled && level >= SpeakingWhileMutedDetector.audioLevelThreshold
                if isLoudWhileMuted {
                    let newCount = state.consecutiveCount + 1
                    let triggered = newCount >= SpeakingWhileMutedDetector.triggerThreshold
                    return DetectionState(consecutiveCount: newCount, isSpeakingWhileMuted: triggered)
                } else {
                    return DetectionState(consecutiveCount: 0, isSpeakingWhileMuted: false)
                }
            }
            .map(\.isSpeakingWhileMuted)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }()

    // MARK: - Init

    /// Creates a new detector.
    ///
    /// - Parameters:
    ///   - isMicEnabled: A publisher that emits `true` when the local microphone is active.
    ///   - audioLevel: A publisher that emits the local publisher's audio level in [0.0, 1.0].
    public init(
        isMicEnabled: AnyPublisher<Bool, Never>,
        audioLevel: AnyPublisher<Float, Never>
    ) {
        self.isMicEnabled = isMicEnabled
        self.audioLevel = audioLevel
    }
}

// MARK: - Detection State

extension SpeakingWhileMutedDetector {

    /// Internal accumulator for the hysteresis scan.
    struct DetectionState {
        /// Number of consecutive loud-while-muted samples seen so far.
        let consecutiveCount: Int
        /// Whether the speaking-while-muted threshold has been reached.
        let isSpeakingWhileMuted: Bool

        init(consecutiveCount: Int = 0, isSpeakingWhileMuted: Bool = false) {
            self.consecutiveCount = consecutiveCount
            self.isSpeakingWhileMuted = isSpeakingWhileMuted
        }
    }
}
