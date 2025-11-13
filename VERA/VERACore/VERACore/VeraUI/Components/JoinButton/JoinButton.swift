//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

struct JoinButton: View {
    @Binding var roomName: String
    let color: Color

    let onJoinRoom: () -> Void

    var body: some View {
        Button {
            onJoinRoom()
        } label: {
            Text("Join", bundle: .veraCore).foregroundStyle(color)
        }
        .buttonStyle(JoinRoomButtonStyle())
        .disabled(roomName.isEmpty)
    }
}

struct JoinRoomButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 20

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(VERACommonUIAsset.Colors.uiSystemBackground.swiftUIColor)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    JoinButton(roomName: .constant(""), color: VERACommonUIAsset.Colors.vGray0.swiftUIColor) {}
    JoinButton(roomName: .constant("Test"), color: VERACommonUIAsset.Colors.vAccent.swiftUIColor) {}
    JoinButton(roomName: .constant("Test"), color: .red) {}
}
