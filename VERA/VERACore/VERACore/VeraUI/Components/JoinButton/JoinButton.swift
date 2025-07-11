//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

struct JoinButton: View {
    @Binding var roomName: String
    @Binding var roomState: RoomNameState
    
    let onJoinRoom: () -> Void

    var body: some View {
        Button {
            onJoinRoom()
        } label: {
            Text("Join").foregroundStyle(joinColor)
        }
        .buttonStyle(JoinRoomButtonStyle(isEnabled: !roomName.isEmpty))
        .disabled(roomName.isEmpty)
    }
    
    private var joinColor: Color {
        switch roomState {
        case .initial:
            return .uiSecondaryLabel
        case .valid:
            return .accentBlue
        case .invalid:
            return .uiSecondaryLabel
        }
    }
}

struct JoinRoomButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 20

    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.uiSystemBackground)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    JoinButton(roomName: .constant(""), roomState: .constant(.initial)) {}
    JoinButton(roomName: .constant("Test"), roomState: .constant(.valid)) {}
    JoinButton(roomName: .constant("Test"), roomState: .constant(.invalid)) {}
}
