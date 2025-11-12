//
//  Created by Vonage on 14/7/25.
//

import SwiftUI
import VERACommonUI

struct WaitingRoomUserPreviewView: View {
    private let state: WaitingRoomState
    private let userName: Binding<String>
    private let onMicrophoneToggle: () -> Void
    private let onCameraToggle: () -> Void

    init(
        state: WaitingRoomState,
        userName: Binding<String>,
        onMicrophoneToggle: @escaping () -> Void,
        onCameraToggle: @escaping () -> Void
    ) {
        self.state = state
        self.userName = userName
        self.onMicrophoneToggle = onMicrophoneToggle
        self.onCameraToggle = onCameraToggle
    }

    var body: some View {
        ZStack {
            if let publisher = state.publisher {
                PublisherVideoView(videoView: publisher.view)
            } else {
                PublisherVideoView(videoView: nil)
            }

            VStack {
                Spacer()

                if !state.isCameraEnabled || state.publisher == nil {
                    GeometryReader { geometry in
                        let size = min(geometry.size.width, geometry.size.height) * 0.8
                        AvatarInitials(state: .init(userName: userName.wrappedValue))
                            .frame(width: size, height: size)
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                }

                Spacer()

                HStack(spacing: 24) {
                    if state.allowMicrophoneControl {
                        CircularControlImageButton(
                            isActive: state.isMicrophoneEnabled,
                            image: state.isMicrophoneEnabled
                                ? VERACommonUIAsset.microphone2Solid.swiftUIImage
                                : VERACommonUIAsset.micMuteSolid.swiftUIImage,
                            action: onMicrophoneToggle)
                    }
                    if state.allowCameraControl {
                        CircularControlImageButton(
                            isActive: state.isCameraEnabled,
                            image: state.isCameraEnabled
                                ? VERACommonUIAsset.videoSolid.swiftUIImage
                                : VERACommonUIAsset.videoOffSolid.swiftUIImage,
                            action: onCameraToggle)
                    }
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
                allowMicrophoneControl: true,
                allowCameraControl: true,
                cameras: [],
                publisher: nil),
            userName: .constant("Arthur Dent"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: false,
                isCameraEnabled: true,
                allowMicrophoneControl: true,
                allowCameraControl: true,
                cameras: [],
                publisher: nil),
            userName: .constant("Ford Prefect"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                allowMicrophoneControl: true,
                allowCameraControl: true,
                cameras: [],
                publisher: nil),
            userName: .constant("Marvin"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                allowMicrophoneControl: true,
                allowCameraControl: true,
                cameras: [],
                publisher: nil),
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
                isMicrophoneEnabled: true,
                isCameraEnabled: true,
                allowMicrophoneControl: true,
                allowCameraControl: true,
                cameras: [],
                publisher: nil),
            userName: .constant("Arthur Dent"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: false,
                isCameraEnabled: true,
                allowMicrophoneControl: true,
                allowCameraControl: true,
                cameras: [],
                publisher: nil),
            userName: .constant("Ford Prefect"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                allowMicrophoneControl: true,
                allowCameraControl: true,
                cameras: [],
                publisher: nil),
            userName: .constant("Marvin"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )

        WaitingRoomUserPreviewView(
            state: .init(
                roomName: "room name",
                isMicrophoneEnabled: false,
                isCameraEnabled: false,
                allowMicrophoneControl: true,
                allowCameraControl: true,
                cameras: [],
                publisher: nil),
            userName: .constant("Slartibartfast"),
            onMicrophoneToggle: {},
            onCameraToggle: {}
        )
        .preferredColorScheme(.dark)
    }
}
