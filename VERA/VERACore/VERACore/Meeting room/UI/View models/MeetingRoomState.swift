//
//  Created by Vonage on 11/11/25.
//

import Foundation
import VERAConfiguration
import VERADomain

public struct MeetingRoomParticipantsState {
    public let participants: [Participant]
    public let layout: MeetingRoomLayout
    public let activeSpeakerId: String?
}

public struct MeetingRoomState: Equatable {

    public let roomName: RoomName
    public let roomURL: URL?
    public let isMicEnabled: Bool
    public let isCameraEnabled: Bool
    public let allowMicrophoneControl: Bool
    public let allowCameraControl: Bool
    public let showParticipantList: Bool
    public let participants: [Participant]
    public let layout: MeetingRoomLayout
    public let activeSpeakerId: String?
    public let callState: CallState
    public let archivingState: ArchivingState

    public var participantsCount: Int {
        participants.count { !$0.isScreenshare }
    }

    public init(
        roomName: RoomName,
        roomURL: URL?,
        isMicEnabled: Bool,
        isCameraEnabled: Bool,
        participants: [Participant],
        layout: MeetingRoomLayout,
        activeSpeakerId: String?,
        allowMicrophoneControl: Bool,
        allowCameraControl: Bool,
        showParticipantList: Bool,
        callState: CallState,
        archivingState: ArchivingState
    ) {
        self.roomName = roomName
        self.roomURL = roomURL
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.participants = participants
        self.layout = layout
        self.activeSpeakerId = activeSpeakerId
        self.allowMicrophoneControl = allowMicrophoneControl
        self.allowCameraControl = allowCameraControl
        self.showParticipantList = showParticipantList
        self.callState = callState
        self.archivingState = archivingState
    }

    public static let initial = MeetingRoomState(
        roomName: "",
        roomURL: nil,
        isMicEnabled: false,
        isCameraEnabled: false,
        participants: [],
        layout: .activeSpeaker,
        activeSpeakerId: nil,
        allowMicrophoneControl: AppConfig.audioSettings.allowMicrophoneControl,
        allowCameraControl: AppConfig.videoSettings.allowCameraControl,
        showParticipantList: AppConfig.meetingRoomSettings.showParticipantList,
        callState: .idle,
        archivingState: .idle)
}
