//
//  Created by Vonage on 09/07/26.
//

/// Accessibility identifiers for VERAAudioDiagnostics views.
///
/// Use these constants when setting accessibility identifiers on UI elements
/// and when writing Maestro E2E tests.
public enum AudioDiagnosticsAccessibilityID {
    /// The audio output test screen/sheet anchor.
    public static let screen = "audio-output-test-screen"

    /// The play/stop button in the audio output control panel.
    public static let playButton = "audio-output-play-button"

    /// The audio level bar in the audio output control panel.
    public static let levelBar = "audio-output-level-bar"

    /// The audio output test button in the waiting room (next to camera selector).
    public static let waitingRoomButton = "WaitingRoom.AudioOutputTestButton"

    /// The audio test button in the meeting room bottom bar/overflow menu.
    public static let meetingRoomButton = "MeetingRoom.AudioDiagnosticsButton"
}
