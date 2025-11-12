//
//  Created by Vonage on 11/11/25.
//

import Foundation
import VERAConfiguration

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

    public var participantsCount: Int {
        participants.count
    }

    public let showChatButton: Bool
    public let unreadMessagesCount: Int

    public init(
        roomName: RoomName,
        roomURL: URL?,
        isMicEnabled: Bool,
        isCameraEnabled: Bool,
        participants: [Participant],
        layout: MeetingRoomLayout,
        activeSpeakerId: String?,
        showChatButton: Bool,
        unreadMessagesCount: Int = 0,
        allowMicrophoneControl: Bool,
        allowCameraControl: Bool,
        showParticipantList: Bool
    ) {
        self.roomName = roomName
        self.roomURL = roomURL
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.participants = participants
        self.layout = layout
        self.activeSpeakerId = activeSpeakerId
        self.showChatButton = showChatButton
        self.unreadMessagesCount = unreadMessagesCount
        self.allowMicrophoneControl = allowMicrophoneControl
        self.allowCameraControl = allowCameraControl
        self.showParticipantList = showParticipantList
    }

    public static let initial = MeetingRoomState(
        roomName: "",
        roomURL: nil,
        isMicEnabled: false,
        isCameraEnabled: false,
        participants: [],
        layout: .activeSpeaker,
        activeSpeakerId: nil,
        showChatButton: AppConfig.meetingRoomSettings.allowChat,
        allowMicrophoneControl: AppConfig.audioSettings.allowMicrophoneControl,
        allowCameraControl: AppConfig.videoSettings.allowCameraControl,
        showParticipantList: AppConfig.meetingRoomSettings.showParticipantList)
}
