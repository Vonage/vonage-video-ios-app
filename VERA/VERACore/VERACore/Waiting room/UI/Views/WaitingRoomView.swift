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
    }
}

struct HorizontalWaitingRoomContentView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass

    let state: WaitingRoomState
    var userName: Binding<String>
    let onJoinRoom: () -> Void
    let onMicrophoneToggle: () -> Void
    let onCameraToggle: () -> Void

    var body: some View {
        HorizontalContentView(showHeader: verticalSizeClass == .regular) {
            VideoPreviewView(
                state: state,
                userName: userName,
                onMicrophoneToggle: onMicrophoneToggle,
                onCameraToggle: onCameraToggle
            )
        } rightSide: {
            CardView {
                PrepareToJoinRoom(
                    state: state,
                    userName: userName,
                    onJoinRoom: onJoinRoom)
            }
        }
    }
}

struct VerticalWaitingRoomContentView: View {
    let state: WaitingRoomState
    let userName: Binding<String>
    let onJoinRoom: () -> Void
    let onMicrophoneToggle: () -> Void
    let onCameraToggle: () -> Void

    var body: some View {
        VerticalContentView(showLogo: false) {
            VideoPreviewView(
                state: state,
                userName: userName,
                onMicrophoneToggle: onMicrophoneToggle,
                onCameraToggle: onCameraToggle
            )
        } bottomSide: {
            PrepareToJoinRoom(
                state: state,
                userName: userName,
                onJoinRoom: onJoinRoom)
        }
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
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius)
            )
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
                                        .adaptiveFont(.bodyBase)
                                }
                            }
                        }
                    } label: {
                        Label {
                            Text(String(localized: "Camera", bundle: .veraCore))
                                .adaptiveFont(.bodyBase)
                        } icon: {
                            VERACommonUIAsset.Images.videoLine.swiftUIImage
                        }
                    }
                }
            }
            .tint(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
            .padding()
        }
    }

    var cornerRadius: CGFloat {
        if verticalSizeClass == .compact {
            BorderRadius.medium.value
        } else if horizontalSizeClass == .compact {
            BorderRadius.none.value
        } else {
            BorderRadius.medium.value
        }
    }
}

struct PrepareToJoinRoom: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @State var usernameState: VonageTextFieldState = .initial

    let state: WaitingRoomState
    var userName: Binding<String>
    let onJoinRoom: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                UsernameInput(
                    userName: userName,
                    usernameState: $usernameState)
            }
            .padding()

            Divider()

            VStack(alignment: .leading) {
                Text("Prepare to join:", bundle: .veraCore)
                    .font(.headline)
                    .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)

                Text(state.roomName)
                    .font(.subheadline)
                    .foregroundColor(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                    .padding(.bottom, 8)

                JoinRoomButton {
                    usernameState = userName.wrappedValue.getUsernameState(true)
                    onJoinRoom()
                }
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
