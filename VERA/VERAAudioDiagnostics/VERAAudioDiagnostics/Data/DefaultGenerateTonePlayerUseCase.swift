//
//  Created by Vonage on 03/07/26.
//

import AVFoundation
import Foundation

/// Default implementation of ``GenerateTonePlayerUseCase`` that creates a 440Hz test tone.
///
/// Generates a 1-second 440Hz sine wave tone (A4 note) programmatically as a WAV file in memory.
/// This implementation follows the Single Responsibility Principle by focusing solely on
/// audio player generation, separate from playback management.
public struct DefaultGenerateTonePlayerUseCase: GenerateTonePlayerUseCase {

    /// Creates a new instance of the tone player use case.
    ///
    /// This initializer is intentionally empty as the use case is stateless and
    /// generates audio data programmatically without requiring any dependencies.
    public init() {
        // Intentionally empty: this use case is stateless and generates audio data
        // programmatically without requiring any injected dependencies.
    }

    /// Creates an AVAudioPlayer that plays a 1-second 440Hz sine wave tone.
    ///
    /// Uses AVAudioEngine with a source node to generate the tone as PCM data,
    /// then exports to WAV format for playback with AVAudioPlayer.
    ///
    /// - Throws: ``TonePlayerGenerationError/audioDataGenerationFailed`` if tone generation fails,
    ///   or ``TonePlayerGenerationError/playerInitializationFailed(underlyingError:)`` if `AVAudioPlayer` init throws.
    public func callAsFunction() throws -> AVAudioPlayer {
        let sampleRate = AudioDiagnosticsConstants.ToneGeneration.sampleRate
        let duration = AudioDiagnosticsConstants.ToneGeneration.duration
        let frequency = AudioDiagnosticsConstants.ToneGeneration.frequency
        let amplitude = AudioDiagnosticsConstants.ToneGeneration.amplitude

        let frameCount = Int(sampleRate * Float(duration))

        // Set up audio format: 16-bit PCM, mono, 44.1kHz
        guard
            let audioFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: Double(sampleRate),
                channels: AudioDiagnosticsConstants.ToneGeneration.channelCount,
                interleaved: true
            )
        else {
            throw TonePlayerGenerationError.audioDataGenerationFailed
        }

        // Create engine and source node
        let engine = AVAudioEngine()
        let frameCounter = FrameCounterRef()

        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList in
            let audioBuffer = audioBufferList.pointee.mBuffers

            guard let int16Ptr = audioBuffer.mData?.assumingMemoryBound(to: Int16.self) else {
                return noErr
            }

            // Generate sine wave samples
            for frame in 0..<Int(frameCount) {
                let currentFrame = frame + Int(frameCounter.currentFrame)
                let time = Double(currentFrame) / Double(sampleRate)
                let value = sin(2.0 * .pi * frequency * time) * Double(amplitude)
                int16Ptr[frame] = Int16(value * Double(Int16.max))
            }

            frameCounter.currentFrame += Int64(frameCount)
            return noErr
        }

        do {
            // Attach source node to engine
            engine.attach(sourceNode)
            engine.connect(sourceNode, to: engine.mainMixerNode, format: audioFormat)
            try engine.start()

            // Create capture buffer
            guard
                let captureBuffer = AVAudioPCMBuffer(
                    pcmFormat: audioFormat,
                    frameCapacity: AVAudioFrameCount(frameCount)
                )
            else {
                throw TonePlayerGenerationError.audioDataGenerationFailed
            }

            captureBuffer.frameLength = AVAudioFrameCount(frameCount)

            // Manually generate samples by calling the rendering block
            guard let int16Data = captureBuffer.int16ChannelData else {
                throw TonePlayerGenerationError.audioDataGenerationFailed
            }

            let samples = int16Data[0]

            for frame in 0..<frameCount {
                let time = Double(frame) / Double(sampleRate)
                let value = sin(2.0 * .pi * frequency * time) * Double(amplitude)
                samples[frame] = Int16(value * Double(Int16.max))
            }

            // Stop engine
            engine.stop()

            // Convert buffer to WAV data using shared utility
            let wavData = try WAVConverter.convertToWAV(
                buffer: captureBuffer,
                sampleRate: sampleRate
            )

            // Create player from WAV data
            return try AVAudioPlayer(data: wavData)
        } catch {
            engine.stop()
            throw TonePlayerGenerationError.playerInitializationFailed(
                underlyingError: error.localizedDescription
            )
        }
    }
}

// Helper class to maintain mutable frame counter for audio generation
private class FrameCounterRef {
    var currentFrame: Int64 = 0
}
