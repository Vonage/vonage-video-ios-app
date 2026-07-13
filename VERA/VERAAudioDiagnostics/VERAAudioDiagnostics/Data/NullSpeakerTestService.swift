//
//  Created by Vonage on 03/07/26.
//

import Combine

/// A no-op implementation of ``SpeakerTestService`` used in previews and
/// environments where audio playback is not available or desired.
///
/// This implementation provides a safe fallback that:
/// - Never crashes when called
/// - Doesn't produce any audio output
/// - Returns an empty publisher for audio levels
/// - Has minimal performance overhead
///
/// ## Usage
/// Use this service in:
/// - SwiftUI previews where audio playback isn't needed
/// - Unit tests that don't require actual audio functionality
/// - Environments where audio permissions aren't available
/// - As a fallback when the real service initialization fails
///
/// ## Thread Safety
/// This implementation is thread-safe as all methods are no-ops and the publisher
/// is created from `Empty<Float, Never>` which is inherently thread-safe.
public struct NullSpeakerTestService: SpeakerTestService {

    /// Creates a new null speaker test service.
    ///
    /// This initializer is intentionally empty as no setup or dependencies
    /// are required for a no-op implementation.
    public init() {}

    /// No-op implementation that safely ignores the play request.
    ///
    /// This method can be called multiple times without side effects and
    /// will never produce audio output or throw exceptions.
    public func playTestSound() {}

    /// No-op implementation that safely ignores the stop request.
    ///
    /// This method can be called multiple times without side effects,
    /// even if no sound is currently playing.
    public func stopTestSound() {}

    /// Returns an empty publisher that never emits audio level values.
    ///
    /// The returned publisher immediately completes without emitting any values,
    /// which is appropriate for a null implementation where no audio is being processed.
    public var audioLevelPublisher: AnyPublisher<Float, Never> {
        Empty<Float, Never>().eraseToAnyPublisher()
    }
}
