//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERACommonUI

public struct MeetingRoomActions {
    let onShare: (String) -> Void
    let onRetry: () -> Void
    let onToggleMic: () -> Void
    let onToggleCamera: () -> Void
    let onCameraSwitch: () -> Void
    let onEndCall: () -> Void
    let onToggleParticipants: () -> Void
    let onToggleLayout: () -> Void
    let onShowChat: () -> Void

    init(
        onShare: @escaping (String) -> Void = { _ in },
        onRetry: @escaping () -> Void = {},
        onToggleMic: @escaping () -> Void = {},
        onToggleCamera: @escaping () -> Void = {},
        onCameraSwitch: @escaping () -> Void = {},
        onEndCall: @escaping () -> Void = {},
        onToggleParticipants: @escaping () -> Void = {},
        onToggleLayout: @escaping () -> Void = {},
        onShowChat: @escaping () -> Void = {}
    ) {
        self.onShare = onShare
        self.onRetry = onRetry
        self.onToggleMic = onToggleMic
        self.onToggleCamera = onToggleCamera
        self.onCameraSwitch = onCameraSwitch
        self.onEndCall = onEndCall
        self.onToggleParticipants = onToggleParticipants
        self.onToggleLayout = onToggleLayout
        self.onShowChat = onShowChat
    }
}

struct BottomBar: View {

    private let isMicEnabled: Bool
    private let isCameraEnabled: Bool
    private let participantsCount: Int
    private let unreadMessagesCount: Int
    private let showChatButton: Bool
    private let currentLayout: MeetingRoomLayout
    private let actions: MeetingRoomActions

    init(
        isMicEnabled: Bool,
        isCameraEnabled: Bool,
        participantsCount: Int,
        unreadMessagesCount: Int,
        showChatButton: Bool,
        currentLayout: MeetingRoomLayout,
        actions: MeetingRoomActions
    ) {
        self.isMicEnabled = isMicEnabled
        self.isCameraEnabled = isCameraEnabled
        self.participantsCount = participantsCount
        self.unreadMessagesCount = unreadMessagesCount
        self.currentLayout = currentLayout
        self.showChatButton = showChatButton
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
                    iconName: isCameraEnabled ? "video.fill" : "video.slash.fill",
                    action: actions.onToggleCamera)
                LayoutControlButton(layout: currentLayout, action: actions.onToggleLayout)
                ParticipantsBadgeButton(
                    participantsCount: participantsCount,
                    onToggleParticipants: actions.onToggleParticipants)
                if showChatButton {
                    ChatBadgeButton(
                        unreadMessagesCount: unreadMessagesCount,
                        onShowChat: actions.onShowChat)
                }
                EndCallControlButton(action: actions.onEndCall)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(BottomBarBackground())
        .padding(.bottom, 2)
    }
}

struct BottomBarBackground: View {
    var body: some View {
        #if os(macOS)
            RoundedRectangle(cornerRadius: 16)
                .fill(VERACommonUIAsset.vGray4.swiftUIColor.opacity(0.8))
        #else
            Group {
                if #available(iOS 26.0, *) {
                    glassEffectBackground()
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(VERACommonUIAsset.vGray4.swiftUIColor.opacity(0.8))
                }
            }
        #endif
    }

    #if !os(macOS)
        @available(iOS 26.0, *)
        private func glassEffectBackground() -> some View {
            RoundedRectangle(cornerRadius: 16)
                .glassEffect(in: .rect(cornerRadius: 16.0))
        }
    #endif
}

#Preview {
    VStack {
        BottomBar(
            isMicEnabled: false,
            isCameraEnabled: true,
            participantsCount: 25,
            unreadMessagesCount: 5,
            showChatButton: true,
            currentLayout: .activeSpeaker,
            actions: .init())
    }
    .background(Color.black)
}

#Preview {
    VStack {
        BottomBar(
            isMicEnabled: false,
            isCameraEnabled: true,
            participantsCount: 25,
            unreadMessagesCount: 0,
            showChatButton: true,
            currentLayout: .grid,
            actions: .init())
    }
    .background(Color.white)
    .preferredColorScheme(.dark)
}
