//
// AppConfig.swift
// Generated from app-config.json - DO NOT EDIT MANUALLY
//

import Foundation

public struct AppConfig {
    public struct VideoSettings {
        public let allowBackgroundEffects: Bool = true
        public let allowCameraControl: Bool = true
        public let allowVideoOnJoin: Bool = true
        public let defaultResolution: String = "640x480"
    }
    
    public struct AudioSettings {
        public let allowAdvancedNoiseSuppression: Bool = true
        public let allowAudioOnJoin: Bool = true
        public let allowMicrophoneControl: Bool = true
    }
    
    public struct WaitingRoomSettings {
        public let allowDeviceSelection: Bool = true
    }
    
    public struct MeetingRoomSettings {
        public let allowArchiving: Bool = true
        public let allowCaptions: Bool = true
        public let allowChat: Bool = true
        public let allowDeviceSelection: Bool = true
        public let allowEmojis: Bool = true
        public let allowScreenShare: Bool = true
        public let defaultLayoutMode: String = "activespeaker"
        public let showParticipantList: Bool = true
    }
    
    public static let videoSettings = VideoSettings()
    public static let audioSettings = AudioSettings()
    public static let waitingRoomSettings = WaitingRoomSettings()
    public static let meetingRoomSettings = MeetingRoomSettings()
}
