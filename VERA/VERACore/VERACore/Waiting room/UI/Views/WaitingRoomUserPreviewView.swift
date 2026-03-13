//
//  Created by Vonage on 14/7/25.
//

import SwiftUI
import VERACommonUI

public struct ViewHolder: Identifiable {
    public let id: String
    public let content: () -> AnyView

    public init<Content: View>(
        id: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self.content = { AnyView(content()) }
    }
}

struct WaitingRoomUserPreviewView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    private let state: WaitingRoomState
    private let userName: Binding<String>
    @Binding var extraTrailingButtons: [ViewHolder]
    private let onMicrophoneToggle: () -> Void
    private let onCameraToggle: () -> Void

    init(
        state: WaitingRoomState,
        userName: Binding<String>,
        extraTrailingButtons: Binding<[ViewHolder]> = .constant([]),
        onMicrophoneToggle: @escaping () -> Void,
        onCameraToggle: @escaping () -> Void
    ) {
        self.state = state
        self.userName = userName
        self._extraTrailingButtons = extraTrailingButtons
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

            if !extraTrailingButtons.isEmpty {
                HStack {
                    Spacer()
                    VStack {
                        ForEach(extraTrailingButtons) {
                            $0.content()
                                .padding(.leading, 2)
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .topTrailing)
                    .padding(.top, 8)
                    .padding(.trailing, 8)
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

                ZStack(alignment: .bottom) {
                    HStack(spacing: 24) {
                        if state.allowCameraControl {
                            CircularControlImageButton(
                                isActive: state.isCameraEnabled,
                                image: state.isCameraEnabled
                                    ? VERACommonUIAsset.Images.videoLine.swiftUIImage
                                    : VERACommonUIAsset.Images.videoOffLine.swiftUIImage,
                                action: onCameraToggle)
                        }
                        if state.allowMicrophoneControl {
                            CircularControlImageButton(
                                isActive: state.isMicrophoneEnabled,
                                image: state.isMicrophoneEnabled
                                    ? VERACommonUIAsset.Images.microphoneLine.swiftUIImage
                                    : VERACommonUIAsset.Images.micMuteLine.swiftUIImage,
                                action: onMicrophoneToggle)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: horizontalSizeClass == .compact ? .infinity : 480, maxHeight: 320)
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
            extraTrailingButtons: .constant([
                .init(
                    id: "",
                    content: {
                        CircularControlImageButton(
                            isActive: true,
                            image: VERACommonUIAsset.Images.microphoneLine.swiftUIImage
                        ) {}
                    })
            ]),
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
