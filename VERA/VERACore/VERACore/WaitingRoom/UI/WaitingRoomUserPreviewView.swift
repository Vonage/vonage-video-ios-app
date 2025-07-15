//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

struct WaitingRoomUserPreviewView: View {
    private let state: WaitingRoomState
    private let onMicrophoneToggle: () -> Void
    private let onCameraToggle: () -> Void

    init(
        state: WaitingRoomState,
        onMicrophoneToggle: @escaping () -> Void = {},
        onCameraToggle: @escaping () -> Void = {}
    ) {
        self.state = state
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
                            initials: state.initials,
                            color: state.color,
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
                initials: "ZB",
                color: .yellow,
                isMicrophoneEnabled: true,
                isCameraEnabled: true,
                audioDevices: [],
                cameras: []),
            onMicrophoneToggle: { print("Micrófono toggled") },
            onCameraToggle: { print("Cámara toggled") }
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                initials: "AB",
                color: .blue,
                isMicrophoneEnabled: false,
                isCameraEnabled: true,
                audioDevices: [],
                cameras: []),
            onMicrophoneToggle: { print("Micrófono toggled") },
            onCameraToggle: { print("Cámara toggled") }
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                initials: "CD",
                color: .green,
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                audioDevices: [],
                cameras: []),
            onMicrophoneToggle: { print("Micrófono toggled") },
            onCameraToggle: { print("Cámara toggled") }
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                initials: "CD",
                color: .green,
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                audioDevices: [],
                cameras: []),
            onMicrophoneToggle: { print("Micrófono toggled") },
            onCameraToggle: { print("Cámara toggled") }
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                initials: "ZB",
                color: .yellow,
                isMicrophoneEnabled: true,
                isCameraEnabled: true,
                audioDevices: [],
                cameras: []),
            onMicrophoneToggle: { print("Micrófono toggled") },
            onCameraToggle: { print("Cámara toggled") }
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                initials: "AB",
                color: .blue,
                isMicrophoneEnabled: false,
                isCameraEnabled: true,
                audioDevices: [],
                cameras: []),
            onMicrophoneToggle: { print("Micrófono toggled") },
            onCameraToggle: { print("Cámara toggled") }
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                initials: "CD",
                color: .green,
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                audioDevices: [],
                cameras: []),
            onMicrophoneToggle: { print("Micrófono toggled") },
            onCameraToggle: { print("Cámara toggled") }
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                initials: "CD",
                color: .green,
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                audioDevices: [],
                cameras: []),
            onMicrophoneToggle: { print("Micrófono toggled") },
            onCameraToggle: { print("Cámara toggled") }
        )
        .preferredColorScheme(.dark)
    }
}
