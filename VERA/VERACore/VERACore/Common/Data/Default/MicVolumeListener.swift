//
//  Created by Vonage on 27/3/26.
//

import AVFoundation
import Combine
import VERADomain
import os

/// Utility class to listen directly to the device microphone volume.
/// Used in the waiting room to show the volume indicator;
/// in the conference room, the SDK's audio-level listener is used instead.
@MainActor
final class MicVolumeListener {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.vonage", category: "MicVolumeListener")
    nonisolated private static let scale: Float = 10

    private let audioEngine: any MicrophoneAudioEngine
    private var isListening = false
    private var volumeRelay = EventRelay<Float, Never>()

    init(audioEngine: (any MicrophoneAudioEngine)? = nil) {
        self.audioEngine = audioEngine ?? DeviceMicrophoneAudioEngine()
    }

    /// Starts listening to microphone volume and emits normalized audio levels (0.0–1.0).
    ///
    /// - Parameter samplingInterval: Minimum interval between volume samples (default 0.06s).
    /// - Returns: A publisher emitting normalized audio level values.
    func start(samplingInterval: TimeInterval = 0.06) -> AnyPublisher<Float, Never> {
        guard !isListening else {
            return volumeRelay.publisher
                .throttle(for: .seconds(samplingInterval), scheduler: DispatchQueue.main, latest: true)
                .eraseToAnyPublisher()
        }
        let format = audioEngine.inputFormat

        guard format.sampleRate > 0, format.channelCount > 0 else {
            Self.logger.warning(
                "Invalid input format (sampleRate: \(format.sampleRate), channels: \(format.channelCount)). Microphone may be unavailable."
            )
            return
                volumeRelay.publisher
                .throttle(for: .seconds(samplingInterval), scheduler: DispatchQueue.main, latest: true)
                .eraseToAnyPublisher()
        }

        // The real-time callback owns only the Sendable relay for this recording.
        // A late callback after stop cannot reach this listener or a later recording.
        let relay = volumeRelay
        audioEngine.installTap(format: format) { @Sendable buffer in
            let rms = Self.normalizeAudioLevel(buffer: buffer)
            relay.send(min(max(rms, 0), 1))
        }

        isListening = true
        do {
            try audioEngine.start()
        } catch {
            Self.logger.error("Failed to start audio engine: \(error.localizedDescription)")
        }

        return
            volumeRelay.publisher
            .throttle(for: .seconds(samplingInterval), scheduler: DispatchQueue.main, latest: true)
            .eraseToAnyPublisher()
    }

    /// Stops listening to microphone volume.
    func stop() {
        guard isListening else { return }
        isListening = false
        audioEngine.removeTap()
        audioEngine.stop()
        volumeRelay.send(completion: .finished)
        volumeRelay = EventRelay<Float, Never>()
    }

    nonisolated private static func normalizeAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        var sum: Float = 0
        let samples = channelData[0]
        for i in 0..<frameLength {
            sum += samples[i] * samples[i]
        }

        let rms = sqrtf(sum / Float(frameLength))
        // AVAudioEngine float samples are already in -1.0…1.0, so no Short.MAX_VALUE division needed
        return min(max(rms * Self.scale, 0), 1)
    }
}

/// Keeps hardware access separate from recording ownership and audio normalization.
@MainActor
protocol MicrophoneAudioEngine {
    var inputFormat: AVAudioFormat { get }
    func installTap(format: AVAudioFormat, handler: @escaping @Sendable (AVAudioPCMBuffer) -> Void)
    func removeTap()
    func start() throws
    func stop()
}

@MainActor
private final class DeviceMicrophoneAudioEngine: MicrophoneAudioEngine {
    private let engine = AVAudioEngine()
    var inputFormat: AVAudioFormat { engine.inputNode.outputFormat(forBus: 0) }

    func installTap(format: AVAudioFormat, handler: @escaping @Sendable (AVAudioPCMBuffer) -> Void) {
        engine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { @Sendable buffer, _ in
            handler(buffer)
        }
    }

    func removeTap() { engine.inputNode.removeTap(onBus: 0) }
    func start() throws { try engine.start() }
    func stop() { engine.stop() }
}
