//
//  Created by Vonage on 28/5/26.
//

import Foundation

/// Lightweight configuration for the meeting room UI.
///
/// Controls which hardware controls and UI elements are visible
/// in the meeting room bottom bar.
///
/// ## Usage
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

    /// Creates a meeting room configuration.
    ///
    /// - Parameters:
    ///   - allowMicrophoneControl: Show the microphone toggle. Defaults to `true`.
    ///   - allowCameraControl: Show the camera toggle. Defaults to `true`.
    ///   - showParticipantList: Show the participants button. Defaults to `true`.
    public init(
        allowMicrophoneControl: Bool = true,
        allowCameraControl: Bool = true,
        showParticipantList: Bool = true
    ) {
        self.allowMicrophoneControl = allowMicrophoneControl
        self.allowCameraControl = allowCameraControl
        self.showParticipantList = showParticipantList
    }
}

// MARK: - Internal Conversion

import VERAMeetingRoom

extension VERAMeetingRoomSDK.MeetingRoomConfiguration {
    func toInternal() -> VERAMeetingRoom.MeetingRoomConfiguration {
        VERAMeetingRoom.MeetingRoomConfiguration(
            allowMicrophoneControl: allowMicrophoneControl,
            allowCameraControl: allowCameraControl,
            showParticipantList: showParticipantList
        )
    }
}
