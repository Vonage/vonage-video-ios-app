//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

enum RoomNameState {
    case initial, valid, invalid
}

struct JoinExistingRoom: View {

    @State var roomName: String = ""
    @State private var roomState = VonageTextFieldState.initial

    let onJoinRoom: (String) -> Void

    var body: some View {
        HStack {
            VonageTextField(
                iconName: "keyboard",
                placeholder: String(localized: "Enter room name", bundle: .veraCore),
                text: $roomName,
                state: roomState,
                forceLowercase: true)

            JoinButton(roomName: $roomName, color: joinColor) {
                onJoinRoom(roomName)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: roomState)
        }
        .onChange(of: roomName) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                roomState = getRoomState()
            }
        }
    }

    private var borderColor: Color {
        switch getRoomState() {
        case .initial:
            return VERACommonUIAsset.Colors.uiSecondaryLabel.swiftUIColor
        case .valid:
            return VERACommonUIAsset.Colors.accentBlue.swiftUIColor
        case .invalid:
            return .red
        }
    }

    private var joinColor: Color {
        switch roomState {
        case .initial:
            return VERACommonUIAsset.Colors.uiSecondaryLabel.swiftUIColor
        case .valid:
            return VERACommonUIAsset.Colors.accentBlue.swiftUIColor
        case .invalid:
            return VERACommonUIAsset.Colors.uiSecondaryLabel.swiftUIColor
        }
    }

    private func getRoomState() -> VonageTextFieldState {
        if roomName.isEmpty {
            return .initial
        } else {
            return roomName.isValidRoomName ? .valid : .invalid
        }
    }
}

#Preview {
    JoinExistingRoom { _ in }
}
