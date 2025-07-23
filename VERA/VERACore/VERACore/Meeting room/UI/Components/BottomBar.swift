//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

struct MeetingRoomActions {
    let onShare: (String) -> Void = {_ in}
    let onRetry: () -> Void = {}
    let onToggleMic: () -> Void = {}
    let onToggleCamera: () -> Void = {}
    let onEndCall: () -> Void = {}
    let onBack: () -> Void = {}
    let onToggleParticipants: () -> Void = {}
}

struct BottomBar: View {
    
    private let isMicEnabled: Bool
    private let isCameraEnabled: Bool
    private let participantsCount: Int
    private let actions: MeetingRoomActions
    
    init(isMicEnabled: Bool,
         isCameraEnabled: Bool,
         participantsCount: Int,
         actions: MeetingRoomActions
    ) {
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.participantsCount = participantsCount
        self.actions = actions
    }
    
    var body: some View {
        HStack {
            ControlButton(
                isActive: isMicEnabled,
                iconName: isMicEnabled ? "mic.slash.fill" : "mic.fill",
                action: actions.onToggleMic)
            ControlButton(
                isActive: isCameraEnabled,
                iconName: isCameraEnabled ? "video.slash.fill" : "video.fill",
                action: actions.onToggleCamera)
            ControlButton(
                isActive: false,
                iconName: "square.grid.2x2.fill",
                action: {})
            ParticipantsBadgeButton(
                participantsCount: participantsCount,
                onToggleParticipants: actions.onToggleParticipants)
            ControlButton(
                isActive: true,
                iconName: "phone.down.fill",
                action: actions.onEndCall)
        }
    }
}

#Preview {
    BottomBar(isMicEnabled: true, isCameraEnabled: true, participantsCount: 25, actions: .init())
}
