//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

public struct WaitingRoomState: Equatable {
    public let roomName: String
    public let isMicrophoneEnabled: Bool
    public let isCameraEnabled: Bool
    public let audioDevices: [UIAudioDevice]
    public let cameras: [UICameraDevice]

    public init(
        roomName: String,
        isMicrophoneEnabled: Bool,
        isCameraEnabled: Bool,
        audioDevices: [UIAudioDevice],
        cameras: [UICameraDevice]
    ) {
        self.roomName = roomName
        self.isMicrophoneEnabled = isMicrophoneEnabled
        self.isCameraEnabled = isCameraEnabled
        self.audioDevices = audioDevices
        self.cameras = cameras
    }

    public static let `default` = WaitingRoomState(
        roomName: "",
        isMicrophoneEnabled: false,
        isCameraEnabled: false,
        audioDevices: [],
        cameras: []
    )
}

public struct WaitingRoomView: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let state: WaitingRoomState
    var userName: Binding<String>
    let publisherVideoView: PublisherVideoView
    let onJoinRoom: () -> Void
    let onMicrophoneToggle: () -> Void
    let onCameraToggle: () -> Void

    public var body: some View {
        VStack(spacing: 0) {
            if verticalSizeClass == .compact {
                HorizontalWaitingRoomContentView(
                    state: state,
                    userName: userName,
                    publisherVideoView: publisherVideoView,
                    onJoinRoom: onJoinRoom,
                    onMicrophoneToggle: onMicrophoneToggle,
                    onCameraToggle: onCameraToggle)
            } else if horizontalSizeClass == .compact {
                VerticalWaitingRoomContentView(
                    state: state,
                    userName: userName,
                    publisherVideoView: publisherVideoView,
                    onJoinRoom: onJoinRoom,
                    onMicrophoneToggle: onMicrophoneToggle,
                    onCameraToggle: onCameraToggle)
            } else {
                HorizontalWaitingRoomContentView(
                    state: state,
                    userName: userName,
                    publisherVideoView: publisherVideoView,
                    onJoinRoom: onJoinRoom,
                    onMicrophoneToggle: onMicrophoneToggle,
                    onCameraToggle: onCameraToggle)
            }
        }
        .background(.uiSystemBackground)
    }
}

struct HorizontalWaitingRoomContentView: View {
    let state: WaitingRoomState
    var userName: Binding<String>
    let publisherVideoView: PublisherVideoView
    let onJoinRoom: () -> Void
    let onMicrophoneToggle: () -> Void
    let onCameraToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VideoPreviewView(
                state: state,
                userName: userName,
                publisherVideoView: publisherVideoView,
                onMicrophoneToggle: onMicrophoneToggle,
                onCameraToggle: onCameraToggle
            )
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)


            PrepareToJoinRoom(state: state, userName: userName, onJoinRoom: onJoinRoom)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxHeight: .infinity)
        .padding(0)
    }
}

struct VerticalWaitingRoomContentView: View {
    let state: WaitingRoomState
    let userName: Binding<String>
    let publisherVideoView: PublisherVideoView
    @FocusState private var isTextFieldFocused: Bool
    let onJoinRoom: () -> Void
    let onMicrophoneToggle: () -> Void
    let onCameraToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VideoPreviewView(
                state: state,
                userName: userName,
                publisherVideoView: publisherVideoView,
                onMicrophoneToggle: onMicrophoneToggle,
                onCameraToggle: onCameraToggle
            )
            .frame(maxWidth: .infinity)

            PrepareToJoinRoom(state: state, userName: userName, onJoinRoom: onJoinRoom)

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding(0)
    }
}

struct VideoPreviewView: View {
    let state: WaitingRoomState
    let userName: Binding<String>
    let publisherVideoView: PublisherVideoView
    let onMicrophoneToggle: () -> Void
    let onCameraToggle: () -> Void

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        VStack(spacing: 0) {
            WaitingRoomUserPreviewView(
                state: state,
                userName: userName,
                publisherVideoView: publisherVideoView,
                onMicrophoneToggle: onMicrophoneToggle,
                onCameraToggle: onCameraToggle
            )
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .animation(.easeInOut, value: cornerRadius)

            HStack {
                Menu {
                    ForEach(state.audioDevices, id: \.id) { device in
                        Button {
                            device.onTap?()
                        } label: {
                            HStack {
                                Text(device.name)
                                Image(systemName: device.iconName)
                            }
                        }
                    }
                } label: {
                    Label(String(localized: "Microphone", bundle: .veraCore), systemImage: "mic")
                }
                Menu {
                    ForEach(state.cameras, id: \.id) { device in
                        Button {
                            device.onTap?()
                        } label: {
                            HStack {
                                Text(device.name)
                                Image(systemName: device.iconName)
                            }
                        }
                    }
                } label: {
                    Label(String(localized: "Camera", bundle: .veraCore), systemImage: "video")
                }
            }
            .tint(.uiSecondaryLabel)
            .padding()
        }
    }

    var cornerRadius: CGFloat {
        if verticalSizeClass == .compact {
            16
        } else if horizontalSizeClass == .compact {
            0
        } else {
            16
        }
    }
}

struct PrepareToJoinRoom: View {
    let state: WaitingRoomState
    var userName: Binding<String>
    let onJoinRoom: () -> Void


    var body: some View {
        VStack {
            VStack {
                Text("Prepare to join:", bundle: .veraCore)
                    .font(.headline)
                    .foregroundColor(.uiLabel)

                Text(state.roomName)
                    .font(.subheadline)
                    .foregroundColor(.uiLabel)
            }.padding()

            UsernameInput(userName: userName)
                .frame(maxWidth: 300)

            JoinRoomButton {
                onJoinRoom()
            }
            .padding()
        }
    }
}

#Preview {
    WaitingRoomView(
        state: .init(
            roomName: "Room name",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            audioDevices: [
                .init(id: "", name: "Earpiece", iconName: "iphone"),
                .init(id: "", name: "Speaker", iconName: "peaker.wave.3"),
            ],
            cameras: [
                .init(id: "", name: "Front camera", iconName: "person.fill.viewfinder"),
                .init(id: "", name: "Back camera", iconName: "iphone.rear.camera"),
            ]),
        userName: .constant("Zaphod Beeblebrox"),
        publisherVideoView: .init(videoView: nil),
        onJoinRoom: {},
        onMicrophoneToggle: {},
        onCameraToggle: {}
    )
}
