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
            VStack(alignment: .leading, spacing: 8) {
                Text("Join existing meeting")
                    .adaptiveFont(.heading4)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                    .padding(.bottom, 8)

                VonageTextField(
                    placeholder: String(localized: "Room name", bundle: .veraCore),
                    text: $roomName,
                    state: roomState,
                    forceLowercase: true)

                JoinButton(roomName: $roomName, color: joinColor) {
                    onJoinRoom(roomName)
                }
                .padding(.vertical, 16)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: roomState)
            }
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
            return VERACommonUIAsset.SemanticColors.primary.swiftUIColor
        case .valid:
            return VERACommonUIAsset.SemanticColors.primary.swiftUIColor
        case .invalid:
            return .red
        }
    }

    private var joinColor: Color {
        switch roomState {
        case .initial:
            return VERACommonUIAsset.SemanticColors.primary.swiftUIColor
        case .valid:
            return VERACommonUIAsset.SemanticColors.primary.swiftUIColor
        case .invalid:
            return VERACommonUIAsset.SemanticColors.error.swiftUIColor
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
