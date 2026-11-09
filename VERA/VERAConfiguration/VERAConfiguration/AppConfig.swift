//
// AppConfig.swift
// Generated from app-config.json - DO NOT EDIT MANUALLY
//

import Foundation
import VERADomain

public struct AppConfig: Sendable {
    public static let configVersion: String = "1.0.0"

    public struct VideoSettings: Sendable {
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

    public struct AudioSettings: Sendable {
        public let allowAdvancedNoiseSuppression: Bool
        public let allowAudioOnJoin: Bool
        public let allowMicrophoneControl: Bool
        public let allowAudioDiagnostics: Bool

        public init(
            allowAdvancedNoiseSuppression: Bool = true,
            allowAudioOnJoin: Bool = true,
            allowMicrophoneControl: Bool = true,
            allowAudioDiagnostics: Bool = true
        ) {
            self.allowAdvancedNoiseSuppression = allowAdvancedNoiseSuppression
            self.allowAudioOnJoin = allowAudioOnJoin
            self.allowMicrophoneControl = allowMicrophoneControl
            self.allowAudioDiagnostics = allowAudioDiagnostics
        }
    }

    public struct WaitingRoomSettings: Sendable {
        public let allowDeviceSelection: Bool
        public let allowSettings: Bool

        public init(
            allowDeviceSelection: Bool = true,
            allowSettings: Bool = true
        ) {
            self.allowDeviceSelection = allowDeviceSelection
            self.allowSettings = allowSettings
        }
    }

    public struct AuthSettings: Sendable {
        public let allowAuthentication: Bool
        public let idProviders: [String]

        public init(
            allowAuthentication: Bool = false,
            idProviders: [String] = ["okta"]
        ) {
            self.allowAuthentication = allowAuthentication
            self.idProviders = idProviders
        }
    }

    public struct MeetingRoomSettings: Sendable {
        public let allowArchiving: Bool
        public let allowCaptions: Bool
        public let allowCaptionTranslation: Bool
        public let allowChat: Bool
        public let allowDeviceSelection: Bool
        public let allowEmojis: Bool
        public let allowFeedback: Bool
        public let allowPictureInPicture: Bool
        public let allowPostCallTranscription: Bool
        public let allowScreenShare: Bool
        public let defaultLayoutMode: MeetingRoomLayout
        public let showParticipantList: Bool
        public let allowSettings: Bool

        public init(
            allowArchiving: Bool = true,
            allowCaptions: Bool = true,
            allowCaptionTranslation: Bool = true,
            allowChat: Bool = true,
            allowDeviceSelection: Bool = true,
            allowEmojis: Bool = true,
            allowFeedback: Bool = true,
            allowPictureInPicture: Bool = true,
            allowPostCallTranscription: Bool = true,
            allowScreenShare: Bool = true,
            defaultLayoutMode: MeetingRoomLayout = .activeSpeaker,
            showParticipantList: Bool = true,
            allowSettings: Bool = true
        ) {
            self.allowArchiving = allowArchiving
            self.allowCaptions = allowCaptions
            self.allowCaptionTranslation = allowCaptionTranslation
            self.allowChat = allowChat
            self.allowDeviceSelection = allowDeviceSelection
            self.allowEmojis = allowEmojis
            self.allowFeedback = allowFeedback
            self.allowPictureInPicture = allowPictureInPicture
            self.allowPostCallTranscription = allowPostCallTranscription
            self.allowScreenShare = allowScreenShare
            self.defaultLayoutMode = defaultLayoutMode
            self.showParticipantList = showParticipantList
            self.allowSettings = allowSettings
        }
    }

    public static let videoSettings = VideoSettings()
    public static let audioSettings = AudioSettings()
    public static let authSettings = AuthSettings()
    public static let waitingRoomSettings = WaitingRoomSettings()
    public static let meetingRoomSettings = MeetingRoomSettings()

    public let videoSettings: VideoSettings
    public let audioSettings: AudioSettings
    public let authSettings: AuthSettings
    public let waitingRoomSettings: WaitingRoomSettings
    public let meetingRoomSettings: MeetingRoomSettings

    public init(
        videoSettings: VideoSettings = VideoSettings(),
        audioSettings: AudioSettings = AudioSettings(),
        authSettings: AuthSettings = AuthSettings(),
        waitingRoomSettings: WaitingRoomSettings = WaitingRoomSettings(),
        meetingRoomSettings: MeetingRoomSettings = MeetingRoomSettings()
    ) {
        self.audioSettings = audioSettings
        self.authSettings = authSettings
        self.videoSettings = videoSettings
        self.waitingRoomSettings = waitingRoomSettings
        self.meetingRoomSettings = meetingRoomSettings
    }
}
