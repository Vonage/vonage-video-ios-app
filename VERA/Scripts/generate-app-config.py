#!/usr/bin/env python3

import json
import os

def generate_app_config():
    config_path = "./app-config.json"
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

    # Generate Swift code
    swift_code = f'''//
// AppConfig.swift
// Generated from app-config.json - DO NOT EDIT MANUALLY
//

import Foundation

public struct AppConfig {{
    public struct VideoSettings {{
        public let allowBackgroundEffects: Bool = {str(video['allowBackgroundEffects']).lower()}
        public let allowCameraControl: Bool = {str(video['allowCameraControl']).lower()}
        public let allowVideoOnJoin: Bool = {str(video['allowVideoOnJoin']).lower()}
        public let defaultResolution: String = "{video['defaultResolution']}"
    }}
    
    public struct AudioSettings {{
        public let allowAdvancedNoiseSuppression: Bool = {str(audio['allowAdvancedNoiseSuppression']).lower()}
        public let allowAudioOnJoin: Bool = {str(audio['allowAudioOnJoin']).lower()}
        public let allowMicrophoneControl: Bool = {str(audio['allowMicrophoneControl']).lower()}
    }}
    
    public struct WaitingRoomSettings {{
        public let allowDeviceSelection: Bool = {str(waiting['allowDeviceSelection']).lower()}
    }}
    
    public struct MeetingRoomSettings {{
        public let allowArchiving: Bool = {str(meeting['allowArchiving']).lower()}
        public let allowCaptions: Bool = {str(meeting['allowCaptions']).lower()}
        public let allowChat: Bool = {str(meeting['allowChat']).lower()}
        public let allowDeviceSelection: Bool = {str(meeting['allowDeviceSelection']).lower()}
        public let allowEmojis: Bool = {str(meeting['allowEmojis']).lower()}
        public let allowScreenShare: Bool = {str(meeting['allowScreenShare']).lower()}
        public let defaultLayoutMode: String = "{meeting['defaultLayoutMode']}"
        public let showParticipantList: Bool = {str(meeting['showParticipantList']).lower()}
    }}
    
    public static let videoSettings = VideoSettings()
    public static let audioSettings = AudioSettings()
    public static let waitingRoomSettings = WaitingRoomSettings()
    public static let meetingRoomSettings = MeetingRoomSettings()
}}
'''

    # Write file
    with open(output_path, 'w') as f:
        f.write(swift_code)
    
    print(f"✅ Generated AppConfig.swift with chat enabled: {meeting['allowChat']}")

if __name__ == "__main__":
    generate_app_config()