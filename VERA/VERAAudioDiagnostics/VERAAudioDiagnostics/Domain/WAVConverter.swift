//
//  Created by Vonage on 15/07/26.
//

import AVFoundation

/// Utility for converting PCM audio buffers to WAV format data.
enum WAVConverter {
    /// Converts an AVAudioPCMBuffer to WAV format data.
    ///
    /// - Parameters:
    ///   - buffer: The PCM audio buffer to convert.
    ///   - sampleRate: The sample rate in Hz.
    /// - Returns: WAV format data that can be used with AVAudioPlayer.
    /// - Throws: ``TonePlayerGenerationError/audioDataGenerationFailed`` if conversion fails.
    static func convertToWAV(
        buffer: AVAudioPCMBuffer,
        sampleRate: Float
    ) throws -> Data {
        var wavData = Data()

        guard let int16Data = buffer.int16ChannelData else {
            throw TonePlayerGenerationError.audioDataGenerationFailed
        }

        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let frameCount = Int(buffer.frameLength)
        let byteRate = UInt32(sampleRate) * UInt32(numChannels) * UInt32(bitsPerSample / 8)
        let blockAlign = numChannels * (bitsPerSample / 8)
        let subChunk2Size = UInt32(frameCount) * UInt32(bitsPerSample / 8) * UInt32(numChannels)
        let chunkSize = 36 + subChunk2Size

        // RIFF header
        wavData.append(contentsOf: "RIFF".utf8)
        wavData.append(contentsOf: withUnsafeBytes(of: chunkSize.littleEndian) { Array($0) })
        wavData.append(contentsOf: "WAVE".utf8)

        // fmt sub-chunk
        wavData.append(contentsOf: "fmt ".utf8)
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: numChannels.littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        wavData.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })

        // data sub-chunk
        wavData.append(contentsOf: "data".utf8)
        wavData.append(contentsOf: withUnsafeBytes(of: subChunk2Size.littleEndian) { Array($0) })

        // Append PCM samples
        let samples = int16Data[0]
        for frame in 0..<frameCount {
            let sample = samples[frame]
            wavData.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Array($0) })
        }

        return wavData
    }
}
