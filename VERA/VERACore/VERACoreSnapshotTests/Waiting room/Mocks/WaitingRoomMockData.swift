//
//  Created by Vonage on 16/7/25.
//

import Foundation
import VERACore
import VERATestHelpers

func makeWaitingRoomState(
    roomName: String = "dont-panic",
    isMicrophoneEnabled: Bool = true,
    isCameraEnabled: Bool = true,
    allowMicrophoneControl: Bool = true,
    allowCameraControl: Bool = true,
    audioDevices: [UIAudioDevice] = [],
    cameras: [UICameraDevice] = [],
    publisher: VERAPublisher? = MockVERAPublisher()
) -> WaitingRoomState {
    .init(
        roomName: roomName,
        isMicrophoneEnabled: isMicrophoneEnabled,
        isCameraEnabled: isCameraEnabled,
        allowMicrophoneControl: allowMicrophoneControl,
        allowCameraControl: allowCameraControl,
        audioDevices: audioDevices,
        cameras: cameras,
        publisher: publisher)
}
