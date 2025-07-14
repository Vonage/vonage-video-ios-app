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
    public let initials: String
    public let color: Color
    public let isMicrophoneEnabled: Bool
    public let isCameraEnabled: Bool
    public let audioDevices: [UIAudioDevice]
    public let cameras: [UICameraDevice]
    
    public init(
        roomName: String,
        initials: String,
        color: Color,
        isMicrophoneEnabled: Bool,
        isCameraEnabled: Bool,
        audioDevices: [UIAudioDevice],
        cameras: [UICameraDevice]) {
            self.roomName = roomName
            self.initials = initials
            self.color = color
            self.isMicrophoneEnabled = isMicrophoneEnabled
            self.isCameraEnabled = isCameraEnabled
            self.audioDevices = audioDevices
            self.cameras = cameras
    }
    
    static let `default` = WaitingRoomState(
        roomName: "",
        initials: "",
        color: .blue,
        isMicrophoneEnabled: false,
        isCameraEnabled: false,
        audioDevices: [],
        cameras: []
    )
}

public struct WaitingRoomView: View {

    @State private var userName: String = ""
    private let state: WaitingRoomState
    
    private let onJoinRoom: (String) -> Void
    
    public init(state: WaitingRoomState, onJoinRoom: @escaping (String) -> Void) {
        self.state = state
        self.onJoinRoom = onJoinRoom
    }

    public var body: some View {
        VStack(spacing: 0) {
            Banner()
                .frame(height: 70)
                .padding(.horizontal, 8)
            VStack(spacing: 0) {
                WaitingRoomUserPreviewView(state: state)
                .aspectRatio(16/9, contentMode: .fit)
                
                HStack {
                    Menu {
                        ForEach(state.audioDevices, id: \.id) { device in
                            Button(device.name, action: { device.onTap?() })
                        }
                    } label: {
                        Label("Microphone", systemImage: "mic")
                    }
                    Menu {
                        ForEach(state.cameras, id: \.id) { device in
                            Button(device.name, action: { device.onTap?() })
                        }
                    } label: {
                        Label("Camera", systemImage: "video")
                    }
                }
                .tint(.uiSecondaryLabel)
                .padding()
                
                VStack {
                    Text("Prepare to join:")
                        .font(.headline)
                        .foregroundColor(.uiLabel)
                    
                    Text(state.roomName)
                        .font(.subheadline)
                        .foregroundColor(.uiLabel)
                }.padding()
                
                UsernameInput(userName: $userName)
                    .frame(width: 300)
                
                JoinRoomButton(onJoinRoom: {
                    onJoinRoom(userName)
                })
                Spacer()
            }
            .frame(maxHeight: .infinity)
            .padding(0)
        }
        .background(.uiSystemBackground)
        .navigationBarHidden(true)
    }
}

#Preview {
    WaitingRoomView(
        state: .init(
            roomName: "Room name",
            initials: "ZP",
            color: .yellow,
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
        audioDevices: [
            .init(id: "", name: "Earpiece"),
            .init(id: "", name: "Speaker")
        ],
        cameras: [
            .init(id: "", name: "Front camera"),
            .init(id: "", name: "Back camera")
        ])) {_ in }
}
