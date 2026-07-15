//
//  Created by Vonage on 13/07/2026.
//

import AVFoundation

@testable import VERAAudioDiagnostics

class MockGenerateTonePlayerUseCase: GenerateTonePlayerUseCase, @unchecked Sendable {
    private(set) var callCount = 0
    private let shouldReturnNil: Bool
    var shouldFailOnGenerate = false
    var simulateError = false

    // Create a valid WAV file data with 1 second of silence for the mock player
    private lazy var validAudioData: Data = {
        let sampleRate: Float = 44100.0
        let duration = 1.0
        let frameCount = Int(sampleRate * Float(duration))

        // Set up audio format: 16-bit PCM, mono, 44.1kHz
        guard
            let audioFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: Double(sampleRate),
                channels: 1,
                interleaved: true
            )
        else {
            return Data()
        }

        // Create PCM buffer with silence
        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: audioFormat,
                frameCapacity: AVAudioFrameCount(frameCount)
            )
        else {
            return Data()
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        // Convert buffer to WAV data using shared utility
        guard
            let wavData = try? WAVConverter.convertToWAV(
                buffer: buffer,
                sampleRate: sampleRate
            )
        else {
            return Data()
        }

        return wavData
    }()

    init(shouldReturnNil: Bool = false) {
        self.shouldReturnNil = shouldReturnNil
    }

    func callAsFunction() throws -> AVAudioPlayer {
        callCount += 1

        if shouldReturnNil || shouldFailOnGenerate || simulateError {
            throw TonePlayerGenerationError.audioDataGenerationFailed
        }

        // Create a real AVAudioPlayer with minimal valid data
        do {
            return try AVAudioPlayer(data: validAudioData)
        } catch {
            throw TonePlayerGenerationError.playerInitializationFailed(underlyingError: error.localizedDescription)
        }
    }
}
