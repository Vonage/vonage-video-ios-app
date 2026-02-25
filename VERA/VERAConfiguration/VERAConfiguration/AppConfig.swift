//
// AppConfig.swift
// Generated from app-config.json - DO NOT EDIT MANUALLY
//

import Foundation
import VERADomain

public struct AppConfig {
    public struct VideoSettings {
        public let allowBackgroundEffects: Bool
        public let allowCameraControl: Bool
        public let allowVideoOnJoin: Bool
        public let defaultResolution: String

        public init(
            allowBackgroundEffects: Bool = true,
            allowCameraControl: Bool = true,
            allowVideoOnJoin: Bool = true,
            defaultResolution: String = "640x480"
        ) {
            self.allowBackgroundEffects = allowBackgroundEffects
            self.allowCameraControl = allowCameraControl
            self.allowVideoOnJoin = allowVideoOnJoin
            self.defaultResolution = defaultResolution
        }
    }

    public struct AudioSettings {
        public let allowAdvancedNoiseSuppression: Bool
        public let allowAudioOnJoin: Bool
        public let allowMicrophoneControl: Bool

        public init(
            allowAdvancedNoiseSuppression: Bool = true,
            allowAudioOnJoin: Bool = true,
            allowMicrophoneControl: Bool = true
        ) {
            self.allowAdvancedNoiseSuppression = allowAdvancedNoiseSuppression
            self.allowAudioOnJoin = allowAudioOnJoin
            self.allowMicrophoneControl = allowMicrophoneControl
        }
    }

    public struct WaitingRoomSettings {
        public let allowDeviceSelection: Bool

        public init(allowDeviceSelection: Bool = true) {
            self.allowDeviceSelection = allowDeviceSelection
        }
    }

    public struct MeetingRoomSettings {
        public let allowArchiving: Bool
        public let allowCaptions: Bool
        public let allowChat: Bool
        public let allowDeviceSelection: Bool
        public let allowEmojis: Bool
        public let allowScreenShare: Bool
        public let defaultLayoutMode: MeetingRoomLayout
        public let showParticipantList: Bool
        public let allowSettings: Bool

        public init(
            allowArchiving: Bool = true,
            allowCaptions: Bool = true,
            allowChat: Bool = true,
            allowDeviceSelection: Bool = true,
            allowEmojis: Bool = true,
            allowScreenShare: Bool = true,
            defaultLayoutMode: MeetingRoomLayout = .activeSpeaker,
            showParticipantList: Bool = true,
            allowSettings: Bool = true
        ) {
            self.allowArchiving = allowArchiving
            self.allowCaptions = allowCaptions
            self.allowChat = allowChat
            self.allowDeviceSelection = allowDeviceSelection
            self.allowEmojis = allowEmojis
            self.allowScreenShare = allowScreenShare
            self.defaultLayoutMode = defaultLayoutMode
            self.showParticipantList = showParticipantList
            self.allowSettings = allowSettings
        }
    }

    public static let videoSettings = VideoSettings()
    public static let audioSettings = AudioSettings()
    public static let waitingRoomSettings = WaitingRoomSettings()
    public static let meetingRoomSettings = MeetingRoomSettings()

    public let videoSettings: VideoSettings
    public let audioSettings: AudioSettings
    public let waitingRoomSettings: WaitingRoomSettings
    public let meetingRoomSettings: MeetingRoomSettings

    public init(
        videoSettings: VideoSettings = VideoSettings(),
        audioSettings: AudioSettings = AudioSettings(),
        waitingRoomSettings: WaitingRoomSettings = WaitingRoomSettings(),
        meetingRoomSettings: MeetingRoomSettings = MeetingRoomSettings()
    ) {
        self.audioSettings = audioSettings
        self.videoSettings = videoSettings
        self.waitingRoomSettings = waitingRoomSettings
        self.meetingRoomSettings = meetingRoomSettings
    }
}
