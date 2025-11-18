//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

public struct WaitingRoomState: Equatable {
    public let roomName: String
    public let isMicrophoneEnabled: Bool
    public let isCameraEnabled: Bool
    public let allowMicrophoneControl: Bool
    public let allowCameraControl: Bool
    public let cameras: [UICameraDevice]
    public weak var publisher: VERAPublisher?

    public init(
        roomName: String,
        isMicrophoneEnabled: Bool,
        isCameraEnabled: Bool,
        allowMicrophoneControl: Bool,
        allowCameraControl: Bool,
        cameras: [UICameraDevice],
        publisher: VERAPublisher?
    ) {
        self.roomName = roomName
        self.isMicrophoneEnabled = isMicrophoneEnabled
        self.isCameraEnabled = isCameraEnabled
        self.allowMicrophoneControl = allowMicrophoneControl
        self.allowCameraControl = allowCameraControl
        self.cameras = cameras
        self.publisher = publisher
    }

    public static let initial = WaitingRoomState(
        roomName: "",
        isMicrophoneEnabled: false,
        isCameraEnabled: false,
        allowMicrophoneControl: true,
        allowCameraControl: true,
        cameras: [],
        publisher: nil
    )

    public static func == (lhs: WaitingRoomState, rhs: WaitingRoomState) -> Bool {
        lhs.roomName == rhs.roomName && lhs.isMicrophoneEnabled == rhs.isMicrophoneEnabled
            && lhs.isCameraEnabled == rhs.isCameraEnabled
            && lhs.cameras.count == rhs.cameras.count
            && lhs.allowMicrophoneControl == rhs.allowMicrophoneControl
            && lhs.allowCameraControl == rhs.allowCameraControl
    }
}

public struct WaitingRoomView: View {

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let state: WaitingRoomState
    var userName: Binding<String>
    let onJoinRoom: () -> Void
    let onMicrophoneToggle: () -> Void
    let onCameraToggle: () -> Void

    public var body: some View {
        VStack(spacing: 0) {
            if verticalSizeClass == .compact {
                HorizontalWaitingRoomContentView(
                    state: state,
                    userName: userName,
                    onJoinRoom: onJoinRoom,
                    onMicrophoneToggle: onMicrophoneToggle,
                    onCameraToggle: onCameraToggle)
            } else if horizontalSizeClass == .compact {
                VerticalWaitingRoomContentView(
                    state: state,
                    userName: userName,
                    onJoinRoom: onJoinRoom,
                    onMicrophoneToggle: onMicrophoneToggle,
                    onCameraToggle: onCameraToggle)
            } else {
                HorizontalWaitingRoomContentView(
                    state: state,
                    userName: userName,
                    onJoinRoom: onJoinRoom,
                    onMicrophoneToggle: onMicrophoneToggle,
                    onCameraToggle: onCameraToggle)
            }
        }
        .background(VERACommonUIAsset.Colors.uiSystemBackground.swiftUIColor)
    }
}

struct HorizontalWaitingRoomContentView: View {
    let state: WaitingRoomState
    var userName: Binding<String>
    let onJoinRoom: () -> Void
    let onMicrophoneToggle: () -> Void
    let onCameraToggle: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VideoPreviewView(
                state: state,
                userName: userName,
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
    @FocusState private var isTextFieldFocused: Bool
    let onJoinRoom: () -> Void
    let onMicrophoneToggle: () -> Void
    let onCameraToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VideoPreviewView(
                state: state,
                userName: userName,
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
    let onMicrophoneToggle: () -> Void
    let onCameraToggle: () -> Void

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        VStack(spacing: 0) {
            WaitingRoomUserPreviewView(
                state: state,
                userName: userName,
                onMicrophoneToggle: onMicrophoneToggle,
                onCameraToggle: onCameraToggle
            )
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .animation(.easeInOut, value: cornerRadius)

            HStack {
                if state.allowCameraControl {
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
                        Label {
                            Text(String(localized: "Camera", bundle: .veraCore))
                        } icon: {
                            VERACommonUIAsset.Images.videoLine.swiftUIImage
                        }
                    }
                }
            }
            .tint(VERACommonUIAsset.Colors.uiSecondaryLabel.swiftUIColor)
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
        VStack(alignment: .center) {
            Spacer()
            
            VStack {
                UsernameInput(userName: userName)
            }.padding()
            
            
            Divider()
            
            VStack {
                Text("Prepare to join:", bundle: .veraCore)
                    .font(.headline)
                    .foregroundColor(VERACommonUIAsset.Colors.uiLabel.swiftUIColor)

                Text(state.roomName)
                    .font(.subheadline)
                    .foregroundColor(VERACommonUIAsset.Colors.uiLabel.swiftUIColor)
            }.padding()

            JoinRoomButton {
                onJoinRoom()
            }
            .padding()
            Spacer()
        }
    }
}

#Preview {
    WaitingRoomView(
        state: .init(
            roomName: "Room name",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [
                .init(id: "", name: "Front camera", iconName: "person.fill.viewfinder"),
                .init(id: "", name: "Back camera", iconName: "iphone.rear.camera"),
            ],
            publisher: nil),
        userName: .constant("Zaphod Beeblebrox"),
        onJoinRoom: {},
        onMicrophoneToggle: {},
        onCameraToggle: {}
    )
}

#Preview {
    WaitingRoomView(
        state: .init(
            roomName: "Room name",
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            allowMicrophoneControl: true,
            allowCameraControl: true,
            cameras: [
                .init(id: "", name: "Front camera", iconName: "person.fill.viewfinder"),
                .init(id: "", name: "Back camera", iconName: "iphone.rear.camera"),
            ],
            publisher: nil),
        userName: .constant("Zaphod Beeblebrox"),
        onJoinRoom: {},
        onMicrophoneToggle: {},
        onCameraToggle: {}
    )
}
