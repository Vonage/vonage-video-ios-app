#!/usr/bin/env python3

import json
import os

def generate_app_config():
    config_path = "./Config/app-config.json"
    output_path = "./VERAConfiguration/VERAConfiguration/AppConfig.swift"
    
    # Create directory if it doesn't exist
    os.makedirs("./VERAConfiguration/VERAConfiguration", exist_ok=True)

    # Read configuration
    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
    except FileNotFoundError:
        print(f"❌ Error: Missing {config_path}")
        exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing JSON: {e}")
        exit(1)

    # Extract configurations
    video = config['videoSettings']
    audio = config['audioSettings']
    waiting = config['waitingRoomSettings']
    meeting = config['meetingRoomSettings']

    # Helper to convert bool to Swift
    def bool_str(val):
        return "true" if val else "false"

    # Helper to convert layout mode string to enum case
    def layout_mode(val):
        layout_map = {
            "activespeaker": ".activeSpeaker",
            "grid": ".grid"
        }
        return layout_map.get(val.lower(), ".activeSpeaker")
        
    # Generate Swift code
    swift_code = f'''//
// AppConfig.swift
// Generated from app-config.json - DO NOT EDIT MANUALLY
//

import Foundation
import VERADomain

public struct AppConfig {{
    public struct VideoSettings {{
        public let allowBackgroundEffects: Bool
        public let allowCameraControl: Bool
        public let allowVideoOnJoin: Bool
        public let defaultResolution: String

        public init(
            allowBackgroundEffects: Bool = {bool_str(video['allowBackgroundEffects'])},
            allowCameraControl: Bool = {bool_str(video['allowCameraControl'])},
            allowVideoOnJoin: Bool = {bool_str(video['allowVideoOnJoin'])},
            defaultResolution: String = "{video['defaultResolution']}"
        ) {{
            self.allowBackgroundEffects = allowBackgroundEffects
            self.allowCameraControl = allowCameraControl
            self.allowVideoOnJoin = allowVideoOnJoin
            self.defaultResolution = defaultResolution
        }}
    }}

    public struct AudioSettings {{
        public let allowAdvancedNoiseSuppression: Bool
        public let allowAudioOnJoin: Bool
        public let allowMicrophoneControl: Bool

        public init(
            allowAdvancedNoiseSuppression: Bool = {bool_str(audio['allowAdvancedNoiseSuppression'])},
            allowAudioOnJoin: Bool = {bool_str(audio['allowAudioOnJoin'])},
            allowMicrophoneControl: Bool = {bool_str(audio['allowMicrophoneControl'])}
        ) {{
            self.allowAdvancedNoiseSuppression = allowAdvancedNoiseSuppression
            self.allowAudioOnJoin = allowAudioOnJoin
            self.allowMicrophoneControl = allowMicrophoneControl
        }}
    }}

    public struct WaitingRoomSettings {{
        public let allowDeviceSelection: Bool

        public init(allowDeviceSelection: Bool = {bool_str(waiting['allowDeviceSelection'])}) {{
            self.allowDeviceSelection = allowDeviceSelection
        }}
    }}

    public struct MeetingRoomSettings {{
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
            allowArchiving: Bool = {bool_str(meeting['allowArchiving'])},
            allowCaptions: Bool = {bool_str(meeting['allowCaptions'])},
            allowChat: Bool = {bool_str(meeting['allowChat'])},
            allowDeviceSelection: Bool = {bool_str(meeting['allowDeviceSelection'])},
            allowEmojis: Bool = {bool_str(meeting['allowEmojis'])},
            allowScreenShare: Bool = {bool_str(meeting['allowScreenShare'])},
            defaultLayoutMode: MeetingRoomLayout = {layout_mode(meeting['defaultLayoutMode'])},
            showParticipantList: Bool = {bool_str(meeting['showParticipantList'])},
            allowSettings: Bool = {bool_str(meeting['allowSettings'])}
        ) {{
            self.allowArchiving = allowArchiving
            self.allowCaptions = allowCaptions
            self.allowChat = allowChat
            self.allowDeviceSelection = allowDeviceSelection
            self.allowEmojis = allowEmojis
            self.allowScreenShare = allowScreenShare
            self.defaultLayoutMode = defaultLayoutMode
            self.showParticipantList = showParticipantList
            self.allowSettings = allowSettings
        }}
    }}

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
    ) {{
        self.audioSettings = audioSettings
        self.videoSettings = videoSettings
        self.waitingRoomSettings = waitingRoomSettings
        self.meetingRoomSettings = meetingRoomSettings
    }}
}}
'''

    # Write file
    with open(output_path, 'w') as f:
        f.write(swift_code)
    
    print("✅ Generated AppConfig.swift")

if __name__ == "__main__":
    generate_app_config()