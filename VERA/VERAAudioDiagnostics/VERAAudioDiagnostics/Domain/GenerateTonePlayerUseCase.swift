//
//  Created by Vonage on 03/07/26.
//

import AVFoundation
import Foundation

/// A use case that generates audio players for testing purposes.
///
/// This protocol encapsulates the creation of audio players with test tones,
/// following the Single Responsibility Principle by separating audio generation
/// from playback management.
public protocol GenerateTonePlayerUseCase: Sendable {
    /// Generates an AVAudioPlayer configured with a test tone.
    ///
    /// - Returns: A configured AVAudioPlayer ready for testing, or nil if generation fails.
    @Sendable func callAsFunction() -> AVAudioPlayer?
}
