//
//  Created by Vonage on 16/7/25.
//

import Foundation
import VERACore
import VERADomain
import VERATestHelpers

func makeWaitingRoomState(
    roomName: String = "dont-panic",
    isMicrophoneEnabled: Bool = true,
    isCameraEnabled: Bool = true,
    allowMicrophoneControl: Bool = true,
    allowCameraControl: Bool = true,
    cameras: [UICameraDevice] = [],
    publisher: VERAPublisher? = MockVERAPublisher(),
    allowAudioOutputTest: Bool = false,
    allowSettings: Bool = false,
    allowBackgroundEffects: Bool = false,
    allowAudioEffects: Bool = false
) -> WaitingRoomState {
    .init(
        roomName: roomName,
        isMicrophoneEnabled: isMicrophoneEnabled,
        isCameraEnabled: isCameraEnabled,
        allowMicrophoneControl: allowMicrophoneControl,
        allowCameraControl: allowCameraControl,
        cameras: cameras,
        allowAudioOutputTest: allowAudioOutputTest,
        allowSettings: allowSettings,
        allowBackgroundEffects: allowBackgroundEffects,
        allowAudioEffects: allowAudioEffects,
        publisher: publisher)
}
