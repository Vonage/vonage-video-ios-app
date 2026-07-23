//
//  Created by Vonage on 03/07/26.
//

import AVFoundation
import Combine
import os.log

/// Default implementation of ``SpeakerTestService`` that plays a short tone
/// through the device's current audio output route using `AVAudioPlayer`.
///
/// Generates a 1-second 440Hz tone (A4 note) programmatically if no audio file is available.
/// Monitors audio levels in real-time and publishes them via `audioLevelPublisher`.
///
/// Listens to audio route changes and automatically restarts playback when the route changes,
/// ensuring audio plays through the newly selected output device.
///
/// Configures the shared `AVAudioSession` to match the configuration used by CallKit and the
/// Vonage Video SDK (`OTDefaultAudioDeviceIOS`) so that audio intensity remains consistent
/// between the waiting room and the meeting room.
///
/// - SeeAlso: ``AudioDiagnosticsConstants``
public final class DefaultSpeakerTestService: NSObject, SpeakerTestService, @unchecked Sendable {

    /// Logger for audio diagnostics operations.
    private let logger = Logger(subsystem: "VERAAudioDiagnostics", category: "SpeakerTest")

    private var player: AVAudioPlayer?
    private var levelTimer: Timer?
    private var isPlaying: Bool = false
    private var isObservingAudioRoutes: Bool = false
    private let generateTonePlayerUseCase: GenerateTonePlayerUseCase

    private let audioLevelSubject = PassthroughSubject<Float, Never>()
    public var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }

    public init(
        generateTonePlayerUseCase: GenerateTonePlayerUseCase = DefaultGenerateTonePlayerUseCase()
    ) {
        self.generateTonePlayerUseCase = generateTonePlayerUseCase
        super.init()
    }

    deinit {
        #if os(iOS)
            if isObservingAudioRoutes {
                NotificationCenter.default.removeObserver(
                    self,
                    name: AVAudioSession.routeChangeNotification,
                    object: nil
                )
            }
        #endif
    }

    /// Starts listening for audio route changes.
    ///
    /// Registers an observer that automatically restarts playback when the audio
    /// output device changes (e.g. headphones connected, Bluetooth device selected).
    /// On macOS this method has no effect.
    public func startObservingAudioRoutes() {
        #if os(iOS)
            if !isObservingAudioRoutes {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleRouteChange),
                    name: AVAudioSession.routeChangeNotification,
                    object: nil
                )
                isObservingAudioRoutes = true
            }
        #endif
    }

    /// Stops listening for audio route changes.
    ///
    /// Marks the observer as inactive. Actual removal happens in `deinit`.
    /// On macOS this method has no effect.
    public func stopObservingAudioRoutes() {
        #if os(iOS)
            isObservingAudioRoutes = false
        #endif
    }

    #if os(iOS)
        @objc private func handleRouteChange(notification: Notification) {
            // Only restart if we were actively playing
            guard isPlaying else { return }

            // Extract the reason for the route change
            guard let userInfo = notification.userInfo,
                let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
            else {
                return
            }

            // Restart playback for relevant route changes
            switch reason {
            case .newDeviceAvailable, .oldDeviceUnavailable, .override, .categoryChange:
                // Restart playback on the new route
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + AudioDiagnosticsConstants.RouteChange.restartDelay
                ) { [weak self] in
                    self?.restartPlayback()
                }
            default:
                break
            }
        }
    #endif

    public func playTestSound() {
        isPlaying = true
        startObservingAudioRoutes()
        startAudioAndMonitoring()
    }

    public func stopTestSound() {
        stopObservingAudioRoutes()
        stopMonitoring()
        player?.stop()
    }

    private func restartPlayback() {
        guard isPlaying else { return }

        startAudioAndMonitoring()
    }

    private func startAudioAndMonitoring() {
        // Stop any existing playback
        stopMonitoring()
        player?.stop()

        configureAudioSession()

        if player == nil {
            do {
                let newPlayer = try generateTonePlayerUseCase()
                newPlayer.delegate = self
                newPlayer.isMeteringEnabled = true
                newPlayer.numberOfLoops = AudioDiagnosticsConstants.AudioPlayback.infiniteLoops
                newPlayer.volume = AudioDiagnosticsConstants.AudioPlayback.maxVolume
                newPlayer.prepareToPlay()
                newPlayer.play()
                player = newPlayer
            } catch {
                logger.error("Failed to generate tone player: \(error.localizedDescription)")
                stopMonitoring()
                return
            }
        } else {
            // Reuse existing player - restart playback
            player?.currentTime = 0
            player?.volume = AudioDiagnosticsConstants.AudioPlayback.maxVolume
            player?.play()
        }

        // Start monitoring levels
        startMonitoring()
    }

    /// Configures the shared `AVAudioSession` to match the configuration used by CallKit and
    /// the Vonage Video SDK (`OTDefaultAudioDeviceIOS`).
    ///
    /// This ensures that the audio session category, mode, sample rate, and buffer duration
    /// remain consistent when transitioning between the waiting room and the meeting room,
    /// so audio intensity does not change.
    private func configureAudioSession() {
        #if os(iOS)
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(
                    .playAndRecord,
                    mode: .videoChat,
                    options: [
                        .allowBluetoothHFP,
                        .allowBluetoothA2DP,
                    ]
                )

                // Match Vonage SDK sample rate, input channels and buffer duration exactly
                try audioSession.setPreferredSampleRate(
                    AudioDiagnosticsConstants.AudioSessionConfig.sampleRate
                )
                try audioSession.setPreferredInputNumberOfChannels(
                    AudioDiagnosticsConstants.AudioSessionConfig.inputNumberOfChannels
                )
                try audioSession.setPreferredIOBufferDuration(
                    AudioDiagnosticsConstants.AudioSessionConfig.ioBufferDuration
                )

                try audioSession.setActive(true)

                // Manual audio route selection for speaker preference
                // (replaces the removed .defaultToSpeaker option)
                let currentRoute = audioSession.currentRoute
                let hasOnlyEarpiece = currentRoute.outputs.allSatisfy {
                    $0.portType == .builtInReceiver
                }
                if currentRoute.outputs.isEmpty || hasOnlyEarpiece {
                    try audioSession.overrideOutputAudioPort(.speaker)
                }
            } catch {
                logger.error("Failed to configure audio session: \(error.localizedDescription)")
            }
        #endif
    }

    private func startMonitoring() {
        // Update levels every 50ms for smooth animation
        levelTimer = Timer.scheduledTimer(
            withTimeInterval: AudioDiagnosticsConstants.LevelMetering.updateInterval,
            repeats: true
        ) { [weak self] _ in
            self?.updateAudioLevel()
        }
    }

    private func stopMonitoring() {
        isPlaying = false
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevelSubject.send(AudioDiagnosticsConstants.AudioPlayback.silentAudioLevel)
    }

    private func updateAudioLevel() {
        guard let player = player, player.isPlaying else {
            stopMonitoring()
            return
        }

        // Update metering
        player.updateMeters()

        // Get average power for the mono / left channel.
        // Range: -160 dB (silence) to 0 dB (max)
        let averagePower = player.averagePower(
            forChannel: AudioDiagnosticsConstants.LevelMetering.meteringChannel
        )

        // Convert dB to linear scale (0.0 to 1.0)
        // Use minDecibels as minimum threshold for better visual feedback
        let minDb = AudioDiagnosticsConstants.LevelMetering.minDecibels
        let maxDb = AudioDiagnosticsConstants.LevelMetering.maxDecibels
        let range = maxDb - minDb
        let normalizedLevel = max(
            AudioDiagnosticsConstants.AudioPlayback.silentAudioLevel,
            min(
                AudioDiagnosticsConstants.AudioPlayback.maxVolume,
                (averagePower - minDb) / range
            )
        )

        audioLevelSubject.send(normalizedLevel)
    }
}

// MARK: - AVAudioPlayerDelegate

extension DefaultSpeakerTestService: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Since we loop continuously, this should only be called if manually stopped
        stopMonitoring()
    }

    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        logger.error("Audio player decode error: \(error?.localizedDescription ?? "unknown")")
        stopMonitoring()
    }
}
