//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

struct WaitingRoomUserPreviewView: View {
    private let state: WaitingRoomState
    private let userName: Binding<String>
    private let publisherVideoView: PublisherVideoView
    private let onMicrophoneToggle: () -> Void
    private let onCameraToggle: () -> Void

    init(
        state: WaitingRoomState,
        userName: Binding<String>,
        publisherVideoView: PublisherVideoView,
        onMicrophoneToggle: @escaping () -> Void,
        onCameraToggle: @escaping () -> Void
    ) {
        self.state = state
        self.userName = userName
        self.publisherVideoView = publisherVideoView
        self.onMicrophoneToggle = onMicrophoneToggle
        self.onCameraToggle = onCameraToggle
    }

    var body: some View {
        ZStack {
            publisherVideoView

            VStack {
                Spacer()

                if !state.isCameraEnabled || !publisherVideoView.hasVideo {
                    GeometryReader { geometry in
                        let size = min(geometry.size.width, geometry.size.height) * 0.8
                        AvatarInitials(state: .init(userName: userName.wrappedValue))
                            .frame(width: size, height: size)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                }

                Spacer()

                HStack(spacing: 24) {
                    CircularControlButton(
                        isActive: state.isMicrophoneEnabled,
                        iconName: state.isMicrophoneEnabled ? "mic.slash.fill" : "mic.fill",
                        action: onMicrophoneToggle)

                    CircularControlButton(
                        isActive: state.isCameraEnabled,
                        iconName: state.isCameraEnabled ? "video.slash.fill" : "video.fill",
                        action: onCameraToggle)
                }
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: 480, maxHeight: 320)
    }
}

#Preview {
    VStack(spacing: 20) {
        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: true,
                isCameraEnabled: true,
                audioDevices: [],
                cameras: []),
            userName: .constant("Arthur Dent"),
            publisherVideoView: .init(videoView: nil),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: false,
                isCameraEnabled: true,
                audioDevices: [],
                cameras: []),
            userName: .constant("Ford Prefect"),
            publisherVideoView: .init(videoView: nil),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                audioDevices: [],
                cameras: []),
            userName: .constant("Marvin"),
            publisherVideoView: .init(videoView: nil),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                audioDevices: [],
                cameras: []),
            userName: .constant("Slartibartfast"),
            publisherVideoView: .init(videoView: nil),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: true,
                isCameraEnabled: true,
                audioDevices: [],
                cameras: []),
            userName: .constant("Arthur Dent"),
            publisherVideoView: .init(videoView: nil),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: false,
                isCameraEnabled: true,
                audioDevices: [],
                cameras: []),
            userName: .constant("Ford Prefect"),
            publisherVideoView: .init(videoView: nil),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                audioDevices: [],
                cameras: []),
            userName: .constant("Marvin"),
            publisherVideoView: .init(videoView: nil),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                audioDevices: [],
                cameras: []),
            userName: .constant("Slartibartfast"),
            publisherVideoView: .init(videoView: nil),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )
        .preferredColorScheme(.dark)
    }
}
