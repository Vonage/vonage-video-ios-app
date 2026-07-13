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
/// Pass a custom `audioPlayerFactory` in tests to avoid requiring real audio hardware.
public final class DefaultSpeakerTestService: NSObject, SpeakerTestService, @unchecked Sendable {

    /// Logger for audio diagnostics operations.
    private let logger = Logger(subsystem: "VERAAudioDiagnostics", category: "SpeakerTest")

    private var player: AVAudioPlayer?
    private var levelTimer: Timer?
    private var isPlaying: Bool = false
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
        #if os(iOS)
            // Listen for audio route changes
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRouteChange),
                name: AVAudioSession.routeChangeNotification,
                object: nil
            )
        #endif
    }

    deinit {
        #if os(iOS)
            NotificationCenter.default.removeObserver(self)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.restartPlayback()
                }
            default:
                break
            }
        }
    #endif

    public func playTestSound() {
        isPlaying = true
        startAudioAndMonitoring()
    }

    public func stopTestSound() {
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

        #if os(iOS)
            // Configure audio session (iOS only)
            // Use .playAndRecord with .defaultToSpeaker to ensure speaker is an option
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(
                    .playAndRecord,
                    mode: .voiceChat,  // voiceChat mode works better with AVRoutePickerView
                    options: [
                        .allowBluetoothA2DP,
                        .defaultToSpeaker,  // Makes speaker the default, but allows route changes
                    ]
                )
                try audioSession.setActive(true)
            } catch {
                logger.error("Failed to configure audio session: \(error.localizedDescription)")
            }
        #endif

        if player == nil {
            player = generateTonePlayerUseCase()
            player?.delegate = self
            player?.isMeteringEnabled = true
            player?.numberOfLoops = -1  // Loop continuously
            player?.prepareToPlay()
            player?.play()
        }

        // Start monitoring levels
        startMonitoring()
    }

    private func startMonitoring() {
        // Update levels every 0.05 seconds (50ms) for smooth animation
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }
    }

    private func stopMonitoring() {
        isPlaying = false
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevelSubject.send(0.0)
    }

    private func updateAudioLevel() {
        guard let player = player, player.isPlaying else {
            stopMonitoring()
            return
        }

        // Update metering
        player.updateMeters()

        // Get average power for channel 0 (mono or left channel)
        // Range: -160 dB (silence) to 0 dB (max)
        let averagePower = player.averagePower(forChannel: 0)

        // Convert dB to linear scale (0.0 to 1.0)
        // Use -50 dB as minimum threshold for better visual feedback
        let minDb: Float = -50.0
        let normalizedLevel = max(0.0, min(1.0, (averagePower - minDb) / (0 - minDb)))

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
