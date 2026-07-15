//
//  Created by Vonage on 03/07/26.
//

import AVFoundation
import Foundation

/// Errors thrown by ``GenerateTonePlayerUseCase`` implementations.
public enum TonePlayerGenerationError: Error, Equatable {
    /// The WAV audio data could not be constructed (e.g. ASCII encoding failure).
    case audioDataGenerationFailed
    /// `AVAudioPlayer` could not be initialised from the generated data.
    case playerInitializationFailed(underlyingError: String)

    public static func == (lhs: TonePlayerGenerationError, rhs: TonePlayerGenerationError) -> Bool {
        switch (lhs, rhs) {
        case (.audioDataGenerationFailed, .audioDataGenerationFailed): return true
        case (.playerInitializationFailed(let l), .playerInitializationFailed(let r)): return l == r
        default: return false
        }
    }
}

/// A use case that generates audio players for testing purposes.
///
/// This protocol encapsulates the creation of audio players with test tones,
/// following the Single Responsibility Principle by separating audio generation
/// from playback management.
public protocol GenerateTonePlayerUseCase: Sendable {
    /// Generates an AVAudioPlayer configured with a test tone.
    ///
    /// - Returns: A configured AVAudioPlayer ready for testing.
    /// - Throws: ``TonePlayerGenerationError`` if audio data or player creation fails.
    @Sendable func callAsFunction() throws -> AVAudioPlayer
}
