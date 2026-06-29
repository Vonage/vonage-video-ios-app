//
//  Created by Vonage on 15/5/26.
//

enum MeetingRoomAccessibilityID {
    static let screen = "meeting-room-screen"
    static let endCallButton = "meeting-room-end-call-button"
    static let micEnabled = "meeting-room-mic-enabled"
    static let micDisabled = "meeting-room-mic-disabled"
    static let cameraEnabled = "meeting-room-camera-enabled"
    static let cameraDisabled = "meeting-room-camera-disabled"
    static let moreOptionsButton = "meeting-room-more-options-button"
    static let recordingIndicator = "archiving-recording-indicator"

    static func participantCard(_ participantID: String) -> String {
        "participant-card-\(participantID)"
    }

    static func participantForceMuteButton(_ participantID: String) -> String {
        "participant-force-mute-\(participantID)"
    }

    static func participantMicEnabled(_ participantID: String) -> String {
        "participant-mic-\(participantID)-enabled"
    }

    static func participantMicDisabled(_ participantID: String) -> String {
        "participant-mic-\(participantID)-disabled"
    }
}
