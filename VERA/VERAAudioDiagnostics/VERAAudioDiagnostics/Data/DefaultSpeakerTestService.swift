//
//  Created by Vonage on 03/07/26.
//

import AVFoundation
import Combine
import os.log

/// Logger for audio diagnostics operations.
private let logger = Logger(subsystem: "VERAAudioDiagnostics", category: "SpeakerTest")

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

    private let audioPlayerFactory: () -> AVAudioPlayer?
    private var player: AVAudioPlayer?
    private var levelTimer: Timer?
    private var isPlaying: Bool = false

    private let audioLevelSubject = PassthroughSubject<Float, Never>()
    public var audioLevelPublisher: AnyPublisher<Float, Never> {
        audioLevelSubject.eraseToAnyPublisher()
    }

    /// Creates a service that generates a 440Hz test tone programmatically.
    public override convenience init() {
        self.init {
            Self.createTonePlayer()
        }
    }

    /// Creates a service that loads `SpeakerTestTone.aiff` from the given bundle.
    ///
    /// - Parameter bundle: The bundle to search for the audio asset.
    public convenience init(bundle: Bundle) {
        self.init {
            if let url = bundle.url(forResource: "SpeakerTestTone", withExtension: "aiff") {
                return try? AVAudioPlayer(contentsOf: url)
            }
            // Fallback to generated tone
            return Self.createTonePlayer()
        }
    }

    /// Creates a service with a custom audio player factory.
    ///
    /// - Parameter audioPlayerFactory: Closure that returns the `AVAudioPlayer` to use.
    ///   Inject a test double here during unit testing.
    public init(audioPlayerFactory: @escaping () -> AVAudioPlayer?) {
        self.audioPlayerFactory = audioPlayerFactory
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

        private func restartPlayback() {
            guard isPlaying else { return }

            // Stop current playback
            stopMonitoring()
            player?.stop()

            // Reconfigure audio session
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(
                    .playAndRecord,
                    mode: .voiceChat,
                    options: [
                        .allowBluetoothA2DP,
                        .defaultToSpeaker,
                    ]
                )
                try audioSession.setActive(true)
            } catch {
                logger.error("Failed to reconfigure audio session: \(error.localizedDescription)")
            }

            // Create new player and start playback
            player = audioPlayerFactory()
            player?.delegate = self
            player?.isMeteringEnabled = true
            player?.numberOfLoops = -1  // Loop continuously
            player?.prepareToPlay()
            player?.play()

            // Restart monitoring
            startMonitoring()
        }
    #endif

    /// Creates an AVAudioPlayer that plays a 1-second 440Hz sine wave tone.
    private static func createTonePlayer() -> AVAudioPlayer? {
        let sampleRate = 44100.0
        let duration = 1.0
        let frequency = 440.0  // A4 note
        let amplitude: Float = 0.5

        let frameCount = Int(sampleRate * duration)
        var samples = [Int16](repeating: 0, count: frameCount)

        // Generate sine wave
        for i in 0..<frameCount {
            let time = Double(i) / sampleRate
            let value = sin(2.0 * .pi * frequency * time) * Double(amplitude)
            samples[i] = Int16(value * Double(Int16.max))
        }

        // Create WAV file in memory
        var data = Data()

        // WAV header
        data.append("RIFF".data(using: .ascii)!)
        let fileSize = UInt32(36 + frameCount * 2)
        data.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
        data.append("WAVE".data(using: .ascii)!)

        // Format chunk
        data.append("fmt ".data(using: .ascii)!)
        let fmtChunkSize = UInt32(16)
        data.append(contentsOf: withUnsafeBytes(of: fmtChunkSize.littleEndian) { Array($0) })
        let audioFormat = UInt16(1)  // PCM
        data.append(contentsOf: withUnsafeBytes(of: audioFormat.littleEndian) { Array($0) })
        let numChannels = UInt16(1)  // Mono
        data.append(contentsOf: withUnsafeBytes(of: numChannels.littleEndian) { Array($0) })
        let sampleRateInt = UInt32(sampleRate)
        data.append(contentsOf: withUnsafeBytes(of: sampleRateInt.littleEndian) { Array($0) })
        let byteRate = UInt32(sampleRate * 2)  // 2 bytes per sample
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        let blockAlign = UInt16(2)
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        let bitsPerSample = UInt16(16)
        data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })

        // Data chunk
        data.append("data".data(using: .ascii)!)
        let dataSize = UInt32(frameCount * 2)
        data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })

        // Audio samples
        for sample in samples {
            data.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Array($0) })
        }

        // Create player from data
        return try? AVAudioPlayer(data: data)
    }

    public func playTestSound() {
        isPlaying = true

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

        // Stop any existing playback
        stopMonitoring()
        player?.stop()

        // Create and configure player
        player = audioPlayerFactory()
        player?.delegate = self
        player?.isMeteringEnabled = true
        player?.numberOfLoops = -1  // Loop continuously for testing
        player?.prepareToPlay()
        player?.play()

        // Start monitoring levels
        startMonitoring()
    }

    public func stopTestSound() {
        stopMonitoring()
        player?.stop()
        player = nil
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
