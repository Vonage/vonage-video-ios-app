//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

struct JoinExistingRoom: View {

    @State var roomName: String = ""
    @State private var isValidRoom: Bool = false

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
                    .animation(.easeInOut(duration: 0.3), value: isValidRoom)
            )

            JoinButton(roomName: $roomName) {
                onJoinRoom(roomName)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isValidRoom)
        }
        .onChange(of: roomName) { newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                isValidRoom = newValue.isValidRoomName
            }
        }
    }

    private var borderColor: Color {
        isValidRoom ? .accentBlue : Color(.vGray3)
    }
}

#Preview {
    JoinExistingRoom { _ in }
}
