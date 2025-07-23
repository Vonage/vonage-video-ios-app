//
//  Created by Vonage on 7/8/25.
//

import SwiftUI

struct JoinButton: View {
    @Binding var roomName: String
    let color: Color

    let onJoinRoom: () -> Void

    var body: some View {
        Button {
            onJoinRoom()
        } label: {
            Text("Join", bundle: #bundle).foregroundStyle(color)
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
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    JoinButton(roomName: .constant(""), color: .vGray0) {}
    JoinButton(roomName: .constant("Test"), color: .accentBlue) {}
    JoinButton(roomName: .constant("Test"), color: .red) {}
}
