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
    public func callAsFunction() -> AVAudioPlayer? {
        let sampleRate = 44100.0
        let duration = 1.0
        let frequency = 440.0  // A4 note
        let amplitude: Float = 0.5

        let frameCount = Int(sampleRate * duration)
        var samples = [Int16](repeating: 0, count: frameCount)

        // Generate sine wave
        for index in 0..<frameCount {
            let time = Double(index) / sampleRate
            let value = sin(2.0 * .pi * frequency * time) * Double(amplitude)
            samples[index] = Int16(value * Double(Int16.max))
        }

        // Create WAV file in memory
        var data = Data()

        // WAV header
        guard let riffData = "RIFF".data(using: .ascii),
            let waveData = "WAVE".data(using: .ascii),
            let fmtData = "fmt ".data(using: .ascii),
            let dataChunkData = "data".data(using: .ascii)
        else {
            return nil
        }

        data.append(riffData)
        let fileSize = UInt32(36 + frameCount * 2)
        data.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
        data.append(waveData)

        // Format chunk
        data.append(fmtData)
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
        data.append(dataChunkData)
        let dataSize = UInt32(frameCount * 2)
        data.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })

        // Audio samples
        for sample in samples {
            data.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Array($0) })
        }

        // Create player from data
        return try? AVAudioPlayer(data: data)
    }
}
