//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

enum RoomNameState {
    case initial, valid, invalid
}

struct JoinExistingRoom: View {

    @State var roomName: RoomName = ""
    @State private var roomState = VonageTextFieldState.initial

    let onJoinRoom: (String) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Join existing meeting", bundle: .veraCore)
                    .adaptiveFont(.heading4)
                    .foregroundStyle(VERACommonUIAsset.SemanticColors.textSecondary.swiftUIColor)
                    .padding(.bottom, 8)

                VonageTextField(
                    placeholder: String(localized: "Room name", bundle: .veraCore),
                    text: $roomName,
                    state: roomState,
                    forceLowercase: true)

                JoinButton(color: joinColor) {
                    roomState = getRoomState(true)
                    onJoinRoom(roomName)
                }
                .padding(.vertical, 16)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: roomState)
            }
        }
        .keyboardAware()
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
        VERACommonUIAsset.SemanticColors.primary.swiftUIColor
    }

    private func getRoomState(_ joinPressed: Bool = false) -> VonageTextFieldState {
        if joinPressed {
            if roomName.isEmpty {
                return .invalid(InvalidRoomName.empty.rawValue)
            } else {
                return roomName.isValidRoomName
                    ? .valid : .invalid(InvalidRoomName.containsSpaceOrSpecialCharacter.rawValue)
            }
        }
        if roomName.isEmpty {
            return .initial
        } else {
            return roomName.isValidRoomName
                ? .valid : .invalid(InvalidRoomName.containsSpaceOrSpecialCharacter.rawValue)
        }
    }
}

enum InvalidRoomName: String {
    case empty = "Room name cannot be empty"
    case containsSpaceOrSpecialCharacter = "Cannot be empty, contain spaces or special characters"
}

#Preview {
    JoinExistingRoom { _ in }
}
