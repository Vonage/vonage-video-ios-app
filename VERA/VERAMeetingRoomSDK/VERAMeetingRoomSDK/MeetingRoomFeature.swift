//
//  Created by Vonage on 16/4/26.
//

import Foundation

/// Features that can be enabled at runtime in the meeting room SDK.
///
/// Replace compile-time `#if FEATURE_ENABLED` flags with runtime configuration
/// by passing a set of ``MeetingRoomFeature`` values to ``MeetingRoomBuilder``.
///
/// ## Usage
/// ```swift
/// let builder = MeetingRoomBuilder()
///     .enabledFeatures([.chat, .captions, .reactions])
/// ```
public enum MeetingRoomFeature: String, Hashable, Sendable, CaseIterable {
    /// In-call text chat between participants.
    case chat

    /// Session recording (archiving) with start/stop controls.
    case archiving

    /// Live captions overlay during the call.
    case captions

    /// Emoji reactions with floating animation overlay.
    case reactions

    /// In-call settings panel (resolution, codecs, stats).
    case settings

    /// Screen sharing via ReplayKit broadcast extension.
    case screenShare

    /// Background blur / virtual background effects.
    case backgroundEffects

    /// Advanced noise suppression for the microphone.
    case audioEffects

    /// Audio output testing and diagnostics.
    case audioDiagnostics

    /// CallKit integration.
    case callKit

    /// Feedback form
    case feedback
}
