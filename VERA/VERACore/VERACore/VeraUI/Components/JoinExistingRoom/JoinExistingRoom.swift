//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

enum RoomNameState {
    case initial, valid, invalid
}

struct JoinExistingRoom: View {

    @State var roomName: String = ""
    @State private var roomState: RoomNameState = RoomNameState.initial

    let onJoinRoom: (String) -> Void

    var body: some View {

        HStack {
            HStack(spacing: 12) {
                Image("keyboard", bundle: .veraCore)
                    .foregroundColor(.vGray3)
                    .frame(width: 20)

                TextField("Enter room name", text: $roomName)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.uiSystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: 1.5)
                    )
                    .animation(.easeInOut(duration: 0.3), value: roomState)
            )

            JoinButton(roomName: $roomName) {
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
            return .uiSecondaryLabel
        case .valid:
            return .accentBlue
        case .invalid:
            return .red
        }
    }

    private func getRoomState() -> RoomNameState {
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
