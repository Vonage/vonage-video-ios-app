//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

public struct UIAudioDevice: Identifiable, Equatable {
    public let id: String
    public let name: String

    public var onTap: (() -> Void)?

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    public static func == (lhs: UIAudioDevice, rhs: UIAudioDevice) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

public struct UICameraDevice: Identifiable, Equatable {
    public let id: String
    public let name: String

    public var onTap: (() -> Void)?

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    public static func == (lhs: UICameraDevice, rhs: UICameraDevice) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

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

    static let `default` = WaitingRoomState(
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
                        Button(device.name) { device.onTap?() }
                    }
                } label: {
                    Label("Microphone", systemImage: "mic")
                }
                Menu {
                    ForEach(state.cameras, id: \.id) { device in
                        Button(device.name) { device.onTap?() }
                    }
                } label: {
                    Label("Camera", systemImage: "video")
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
                Text("Prepare to join:")
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
                .init(id: "", name: "Earpiece"),
                .init(id: "", name: "Speaker"),
            ],
            cameras: [
                .init(id: "", name: "Front camera"),
                .init(id: "", name: "Back camera"),
            ]),
        userName: .constant("Zaphod Beeblebrox"),
        publisherVideoView: .init(videoView: nil),
        onJoinRoom: {},
        onMicrophoneToggle: {},
        onCameraToggle: {}
    )
}
