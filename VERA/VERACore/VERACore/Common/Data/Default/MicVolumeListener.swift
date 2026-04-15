//
//  Created by Vonage on 27/3/26.
//

import AVFoundation
import Combine
import os

/// Utility class to listen directly to the device microphone volume.
/// Used in the waiting room to show the volume indicator;
/// in the conference room, the SDK's audio-level listener is used instead.
final class MicVolumeListener {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.vonage", category: "MicVolumeListener")
    private static let scale: Float = 10

    private let audioEngine = AVAudioEngine()
    private var volumeSubject = PassthroughSubject<Float, Never>()

    /// Starts listening to microphone volume and emits normalized audio levels (0.0–1.0).
    ///
    /// - Parameter samplingInterval: Minimum interval between volume samples (default 0.06s).
    /// - Returns: A publisher emitting normalized audio level values.
    func start(samplingInterval: TimeInterval = 0.06) -> AnyPublisher<Float, Never> {
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.sampleRate > 0, format.channelCount > 0 else {
            Self.logger.warning(
                "Invalid input format (sampleRate: \(format.sampleRate), channels: \(format.channelCount)). Microphone may be unavailable."
            )
            return
                volumeSubject
                .throttle(for: .seconds(samplingInterval), scheduler: DispatchQueue.main, latest: true)
                .eraseToAnyPublisher()
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            let rms = self.normalizeAudioLevel(buffer: buffer)
            self.volumeSubject.send(min(max(rms, 0), 1))
        }

        do {
            try audioEngine.start()
        } catch {
            Self.logger.error("Failed to start audio engine: \(error.localizedDescription)")
        }

        return
            volumeSubject
            .throttle(for: .seconds(samplingInterval), scheduler: DispatchQueue.main, latest: true)
            .eraseToAnyPublisher()
    }

    /// Stops listening to microphone volume.
    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        volumeSubject.send(completion: .finished)
        volumeSubject = PassthroughSubject<Float, Never>()
    }

    private func normalizeAudioLevel(buffer: AVAudioPCMBuffer) -> Float {
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
