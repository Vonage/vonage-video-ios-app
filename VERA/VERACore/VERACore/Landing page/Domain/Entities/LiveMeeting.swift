//
//  Created by Vonage on 9/7/25.
//

import Foundation

public struct LiveMeeting {
    public let id: String
    public let roomName: String
    public let participants: [Participant]
    public let isActive: Bool
    public let isRecording: Bool
    public let selectedCamera: CameraDevice
    public let selectedAudio: String
    public let availableCameraDevices: [CameraDevice]
    public let availableAudioDevices: [AudioDevice]
    public let captions: [Caption]
    public let endedAt: Date?
}
