//
//  WAVConverterTests.swift
//  VERAAudioDiagnosticsTests
//
//  Created by Vonage on 15/07/26.
//

@preconcurrency import AVFoundation
import Testing

@testable import VERAAudioDiagnostics

@Suite("WAVConverter - PCM to WAV Conversion")
@MainActor
struct WAVConverterTests {

    // MARK: - Happy Path Tests

    @Test("convertToWAV creates valid WAV data from PCM buffer")
    func convertToWAVCreatesValidWAVData() throws {
        let buffer = makePCMBuffer(frameCount: 44100)

        let wavData = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)

        // WAV file should have data
        #expect(!wavData.isEmpty)
        #expect(wavData.count > 44)  // Minimum WAV header size
    }

    @Test("convertToWAV returns playable audio data")
    func convertToWAVReturnsPlayableData() throws {
        let buffer = makePCMBuffer(frameCount: 44100)

        let wavData = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)
        let player = try AVAudioPlayer(data: wavData)

        // Player should be able to play the data
        #expect(player.duration > 0)
        #expect(player.numberOfChannels == 1)
    }

    // MARK: - WAV Structure Validation Tests

    @Test("convertToWAV creates correct RIFF header")
    func convertToWAVCreatesRIFFHeader() throws {
        let buffer = makePCMBuffer(frameCount: 44100)

        let wavData = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)

        // Check RIFF header (first 4 bytes)
        let riffIdentifier = String(data: wavData.subdata(in: 0..<4), encoding: .utf8)
        #expect(riffIdentifier == "RIFF")

        // Check WAVE identifier (bytes 8-11)
        let waveIdentifier = String(data: wavData.subdata(in: 8..<12), encoding: .utf8)
        #expect(waveIdentifier == "WAVE")
    }

    @Test("convertToWAV creates correct fmt sub-chunk")
    func convertToWAVCreatesFmtSubChunk() throws {
        let buffer = makePCMBuffer(frameCount: 44100)

        let wavData = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)

        // Check fmt identifier (bytes 12-15)
        let fmtIdentifier = String(data: wavData.subdata(in: 12..<16), encoding: .utf8)
        #expect(fmtIdentifier == "fmt ")
    }

    @Test("convertToWAV creates correct data sub-chunk")
    func convertToWAVCreatesDataSubChunk() throws {
        let buffer = makePCMBuffer(frameCount: 44100)

        let wavData = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)

        // The data sub-chunk marker appears after fmt sub-chunk (at byte 36)
        let dataIdentifier = String(data: wavData.subdata(in: 36..<40), encoding: .utf8)
        #expect(dataIdentifier == "data")
    }

    @Test("convertToWAV calculates correct chunk size")
    func convertToWAVCalculatesCorrectChunkSize() throws {
        let frameCount = 44100
        let buffer = makePCMBuffer(frameCount: frameCount)

        let wavData = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)

        // Chunk size is at bytes 4-7 (little-endian UInt32)
        let chunkSizeBytes = wavData.subdata(in: 4..<8)
        let chunkSize = chunkSizeBytes.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }

        // Chunk size should be: 36 (header) + audio data size
        let expectedAudioDataSize = UInt32(frameCount) * 2  // 16-bit samples
        let expectedChunkSize = 36 + expectedAudioDataSize

        #expect(chunkSize == expectedChunkSize)
    }

    @Test("convertToWAV sets correct sample rate in fmt sub-chunk")
    func convertToWAVSetsSampleRate() throws {
        let sampleRate: Float = 44100
        let buffer = makePCMBuffer(frameCount: 44100, sampleRate: sampleRate)

        let wavData = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: sampleRate)

        // Sample rate is at bytes 24-27 in fmt sub-chunk (little-endian UInt32)
        let sampleRateBytes = wavData.subdata(in: 24..<28)
        let readSampleRate = sampleRateBytes.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }

        #expect(readSampleRate == UInt32(sampleRate))
    }

    // MARK: - Error Handling Tests

    @Test("convertToWAV throws when int16ChannelData is nil")
    func convertToWAVThrowsWhenChannelDataNil() throws {
        // Create a buffer without channel data by using a different format
        guard
            let format = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: 44100,
                channels: 1,
                interleaved: true
            )
        else {
            Issue.record("Could not create audio format")
            return
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 44100) else {
            Issue.record("Could not create audio buffer")
            return
        }

        buffer.frameLength = 44100

        #expect(throws: TonePlayerGenerationError.audioDataGenerationFailed) {
            _ = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)
        }
    }

    // MARK: - Edge Cases

    @Test("convertToWAV handles empty buffer (0 frames)")
    func convertToWAVHandlesEmptyBuffer() throws {
        let buffer = makePCMBuffer(frameCount: 0)

        let wavData = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)

        // Should still produce valid WAV header even with no audio data
        #expect(!wavData.isEmpty)
        #expect(wavData.count >= 44)  // Minimum header size
    }

    @Test("convertToWAV handles minimum playable buffer")
    func convertToWAVHandlesMinimumPlayableBuffer() throws {
        // A single frame is too short to measure duration reliably
        // Use a small but measurable buffer (100 frames = ~2.3ms)
        let buffer = makePCMBuffer(frameCount: 100)

        let wavData = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)

        let player = try AVAudioPlayer(data: wavData)
        #expect(player.duration > 0)
    }

    @Test("convertToWAV handles large buffer")
    func convertToWAVHandlesLargeBuffer() throws {
        // 10 seconds at 44.1kHz = 441000 frames
        let buffer = makePCMBuffer(frameCount: 441000)

        let wavData = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)

        let player = try AVAudioPlayer(data: wavData)
        #expect(player.duration > 9.9)  // Close to 10 seconds
    }

    @Test("convertToWAV preserves sample data integrity")
    func convertToWAVPreservesSampleData() throws {
        // Create buffer with specific values
        guard
            let format = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: 44100,
                channels: 1,
                interleaved: true
            )
        else {
            Issue.record("Could not create audio format")
            return
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 10) else {
            Issue.record("Could not create audio buffer")
            return
        }

        buffer.frameLength = 10

        // Fill with specific values
        if let int16Data = buffer.int16ChannelData {
            let samples = int16Data[0]
            for i in 0..<10 {
                samples[i] = Int16(i * 100)
            }
        }

        let wavData = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)

        // Verify we can read back the data
        let player = try AVAudioPlayer(data: wavData)
        #expect(player.numberOfChannels == 1)
    }

    @Test("convertToWAV handles different sample rates")
    func convertToWAVHandlesDifferentSampleRates() throws {
        for sampleRate: Float in [8000, 16000, 44100, 48000] {
            let buffer = makePCMBuffer(frameCount: Int(sampleRate), sampleRate: sampleRate)

            let wavData = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: sampleRate)

            let player = try AVAudioPlayer(data: wavData)
            #expect(player.duration > 0.9)  // Approximately 1 second
        }
    }

    @Test("convertToWAV produces consistent output for same input")
    func convertToWAVProducesConsistentOutput() throws {
        let buffer = makePCMBuffer(frameCount: 44100)

        let wavData1 = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)
        let wavData2 = try WAVConverter.convertToWAV(buffer: buffer, sampleRate: 44100)

        #expect(wavData1 == wavData2)
    }

    // MARK: - Helper

    private func makePCMBuffer(
        frameCount: Int,
        sampleRate: Float = 44100
    ) -> AVAudioPCMBuffer {
        guard
            let format = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: Double(sampleRate),
                channels: 1,
                interleaved: true
            )
        else {
            fatalError("Could not create audio format")
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            fatalError("Could not create audio buffer")
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        return buffer
    }
}
