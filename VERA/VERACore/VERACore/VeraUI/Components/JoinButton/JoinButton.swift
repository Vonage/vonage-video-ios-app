//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

struct JoinButton: View {
    @Binding var roomName: String
    
    let onJoinRoom: () -> Void
    
    var body: some View {
        Button {
            onJoinRoom()
        } label: {
            Text("Join").tint(.vGray3)
        }
        .buttonStyle(JoinRoomButtonStyle(isEnabled: !roomName.isEmpty))
        .disabled(roomName.isEmpty)
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
            .foregroundStyle(isEnabled ? .accentBlue : .vGray3)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    JoinButton(roomName: .constant("")) {}
    JoinButton(roomName: .constant("Test")) {}
}
