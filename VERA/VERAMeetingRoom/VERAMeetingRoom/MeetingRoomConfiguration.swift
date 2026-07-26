//
//  Created by Vonage on 14/04/2026.
//

import Foundation

/// Lightweight configuration for the meeting room module.
///
/// Replaces the full ``AppConfig`` dependency so that ``VERAMeetingRoom``
/// depends only on ``VERADomain`` and ``VERACommonUI`` — not on ``VERAConfiguration``.
///
/// ## Standalone usage
/// ```swift
/// let config = MeetingRoomConfiguration(
///     allowMicrophoneControl: true,
///     allowCameraControl: true,
///     showParticipantList: false
/// )
/// ```
public struct MeetingRoomConfiguration: Equatable, Sendable {

    /// Whether the microphone toggle button is shown in the bottom bar.
    public let allowMicrophoneControl: Bool

    /// Whether the camera toggle button is shown in the bottom bar.
    public let allowCameraControl: Bool

    /// Whether the participant-list button is shown in the bottom bar.
    public let showParticipantList: Bool

    /// Whether Picture-in-Picture is enabled.
    public let allowPictureInPicture: Bool

    /// Creates a meeting room configuration.
    ///
    /// - Parameters:
    ///   - allowMicrophoneControl: Show the microphone toggle. Defaults to `true`.
    ///   - allowCameraControl: Show the camera toggle. Defaults to `true`.
    ///   - showParticipantList: Show the participants button. Defaults to `true`.
    ///   - allowPictureInPicture: Enable Picture-in-Picture. Defaults to `true`.
    public init(
        allowMicrophoneControl: Bool = true,
        allowCameraControl: Bool = true,
        showParticipantList: Bool = true,
        allowPictureInPicture: Bool = true
    ) {
        self.allowMicrophoneControl = allowMicrophoneControl
        self.allowCameraControl = allowCameraControl
        self.showParticipantList = showParticipantList
        self.allowPictureInPicture = allowPictureInPicture
    }
}
