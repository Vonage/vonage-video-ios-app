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

    // Create a minimal valid WAV file data for the mock player
    private lazy var validAudioData: Data = {
        var data = Data()

        // Minimal WAV header
        data.append("RIFF".data(using: .ascii) ?? Data())
        data.append(contentsOf: withUnsafeBytes(of: UInt32(44).littleEndian) { Array($0) })
        data.append("WAVE".data(using: .ascii) ?? Data())
        data.append("fmt ".data(using: .ascii) ?? Data())
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(44100).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(88200).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) })
        data.append("data".data(using: .ascii) ?? Data())
        data.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian) { Array($0) })

        return data
    }()

    init(shouldReturnNil: Bool = false) {
        self.shouldReturnNil = shouldReturnNil
    }

    func callAsFunction() -> AVAudioPlayer? {
        callCount += 1

        if shouldReturnNil || shouldFailOnGenerate || simulateError {
            return nil
        }

        // Create a real AVAudioPlayer with minimal valid data
        return try? AVAudioPlayer(data: validAudioData)
    }
}
