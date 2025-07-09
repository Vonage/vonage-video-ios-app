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
    
    init(id: String, roomName: String, participants: [Participant], isActive: Bool, isRecording: Bool, selectedCamera: CameraDevice, selectedAudio: String, availableCameraDevices: [CameraDevice], availableAudioDevices: [AudioDevice], captions: [Caption], endedAt: Date?) {
        self.id = id
        self.roomName = roomName
        self.participants = participants
        self.isActive = isActive
        self.isRecording = isRecording
        self.selectedCamera = selectedCamera
        self.selectedAudio = selectedAudio
        self.availableCameraDevices = availableCameraDevices
        self.availableAudioDevices = availableAudioDevices
        self.captions = captions
        self.endedAt = endedAt
    }
}
