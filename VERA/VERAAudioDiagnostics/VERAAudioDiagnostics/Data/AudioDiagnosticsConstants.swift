//
//  Created by Vonage on 03/07/26.
//

import AVFoundation
import Foundation

/// Constants used across the audio diagnostics implementation.
///
/// Values are grouped by concern:
/// - ``AudioSessionConfig``: `AVAudioSession` settings that match the Vonage Video SDK
///   (`OTDefaultAudioDeviceIOS`) so audio intensity stays consistent when transitioning
///   from the waiting room to the meeting room.
/// - ``AudioPlayback``: `AVAudioPlayer` playback settings (volume, looping, silent level).
/// - ``LevelMetering``: Parameters used to normalize `AVAudioPlayer` power readings into
///   a 0.0 - 1.0 range for visualization.
/// - ``RouteChange``: Delays and timing related to audio route change handling.
/// - ``ToneGeneration``: Parameters used to generate the test tone signal.
enum AudioDiagnosticsConstants {

    /// `AVAudioSession` configuration that matches the Vonage Video SDK
    /// (`OTDefaultAudioDeviceIOS`) audio session setup exactly.
    enum AudioSessionConfig {
        /// Preferred sample rate in Hz. Matches Vonage SDK.
        static let sampleRate: Double = 48_000.0

        /// Preferred IO buffer duration in seconds (10ms).
        /// Matches Vonage SDK `kPreferredIOBufferDuration`.
        static let ioBufferDuration: TimeInterval = 0.01

        /// Preferred number of input channels (mono). Matches Vonage SDK.
        static let inputNumberOfChannels: Int = 1
    }

    /// `AVAudioPlayer` playback settings.
    enum AudioPlayback {
        /// Maximum player volume (0.0 - 1.0).
        static let maxVolume: Float = 1.0

        /// Reset value emitted through the audio level publisher when playback stops.
        static let silentAudioLevel: Float = 0.0

        /// `AVAudioPlayer.numberOfLoops` sentinel value that loops indefinitely.
        static let infiniteLoops: Int = -1
    }

    /// Audio level metering constants used to normalize `AVAudioPlayer` power readings
    /// into a 0.0 - 1.0 range suitable for visualization.
    enum LevelMetering {
        /// Interval between audio level samples in seconds (50ms).
        static let updateInterval: TimeInterval = 0.05

        /// Minimum decibel threshold. Values below this are clamped to 0.0.
        /// Higher than the -160 dB floor to provide better visual feedback.
        static let minDecibels: Float = -50.0

        /// Maximum decibel value reported by `AVAudioPlayer.averagePower(forChannel:)`.
        static let maxDecibels: Float = 0.0

        /// Channel used to read metering data (mono / left channel).
        static let meteringChannel: Int = 0
    }

    /// Timing constants related to audio route change handling.
    enum RouteChange {
        /// Delay applied before restarting playback after an audio route change (100ms).
        /// Gives the system time to complete the route transition.
        static let restartDelay: TimeInterval = 0.1
    }

    /// Parameters used to generate the test tone signal.
    enum ToneGeneration {
        /// Sample rate used to generate the test tone (44.1 kHz, CD quality).
        static let sampleRate: Float = 44_100.0

        /// Duration of the generated tone in seconds.
        static let duration: Double = 1.0

        /// Tone frequency in Hz (A4 note).
        static let frequency: Double = 440.0

        /// Sine wave amplitude (0.0 - 1.0).
        static let amplitude: Float = 0.5

        /// Number of channels in the generated audio (mono).
        static let channelCount: AVAudioChannelCount = 1
    }
}
