//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

struct WaitingRoomUserPreviewView: View {
    private let state: WaitingRoomState
    private let userName: Binding<String>
    private let onMicrophoneToggle: () -> Void
    private let onCameraToggle: () -> Void

    init(
        state: WaitingRoomState,
        userName: Binding<String>,
        onMicrophoneToggle: @escaping () -> Void = {},
        onCameraToggle: @escaping () -> Void = {}
    ) {
        self.state = state
        self.userName = userName
        self.onMicrophoneToggle = onMicrophoneToggle
        self.onCameraToggle = onCameraToggle
    }

    var body: some View {
        ZStack {
            Color.videoBackground
                .ignoresSafeArea()

            VStack {
                Spacer()

                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height) * 0.8
                    AvatarInitials(
                        state: .init(
                            userName: userName.wrappedValue,
                            isMicrophoneEnabled: state.isMicrophoneEnabled,
                            isCameraEnabled: state.isCameraEnabled)
                    )
                    .frame(width: size, height: size)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }

                Spacer()

                HStack(spacing: 24) {
                    CircularControlButton(
                        isActive: state.isMicrophoneEnabled,
                        iconName: state.isMicrophoneEnabled ? "mic.fill" : "mic.slash.fill",
                        action: onMicrophoneToggle)

                    CircularControlButton(
                        isActive: state.isCameraEnabled,
                        iconName: state.isCameraEnabled ? "video.fill" : "video.slash.fill",
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
                userName: "Arthur Dent",
                color: .yellow,
                isMicrophoneEnabled: true,
                isCameraEnabled: true,
                audioDevices: [],
                cameras: []),
            userName: .constant("Arthur Dent"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                userName: "Ford Prefect",
                color: .blue,
                isMicrophoneEnabled: false,
                isCameraEnabled: true,
                audioDevices: [],
                cameras: []),
            userName: .constant("Ford Prefect"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                userName: "Marvin",
                color: .green,
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                audioDevices: [],
                cameras: []),
            userName: .constant("Marvin"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                userName: "Slartibartfast",
                color: .green,
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                audioDevices: [],
                cameras: []),
            userName: .constant("Slartibartfast"),
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
                userName: "Arthur Dent",
                color: .yellow,
                isMicrophoneEnabled: true,
                isCameraEnabled: true,
                audioDevices: [],
                cameras: []),
            userName: .constant("Arthur Dent"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                userName: "Ford Prefect",
                color: .blue,
                isMicrophoneEnabled: false,
                isCameraEnabled: true,
                audioDevices: [],
                cameras: []),
            userName: .constant("Ford Prefect"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                userName: "Marvin",
                color: .green,
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                audioDevices: [],
                cameras: []),
            userName: .constant("Marvin"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                userName: "Slartibartfast",
                color: .green,
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                audioDevices: [],
                cameras: []),
            userName: .constant("Slartibartfast"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )
        .preferredColorScheme(.dark)
    }
}
