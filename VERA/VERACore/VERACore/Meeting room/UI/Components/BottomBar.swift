//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

struct MeetingRoomActions {
    let onShare: (String) -> Void = { _ in }
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

    init(
        isMicEnabled: Bool,
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
            HStack(alignment: .center) {
                ControlButton(
                    isActive: isMicEnabled,
                    iconName: isMicEnabled ? "mic.fill" : "mic.slash.fill",
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
                EndCallControlButton(action: actions.onEndCall)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }.background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.8))
        ).padding()
    }
}

#Preview {
    VStack {
        BottomBar(isMicEnabled: false, isCameraEnabled: true, participantsCount: 25, actions: .init())
    }
    .background(Color.black)
}

#Preview {
    VStack {
        BottomBar(isMicEnabled: false, isCameraEnabled: true, participantsCount: 25, actions: .init())
    }
    .background(Color.white)
    .preferredColorScheme(.dark)
}
