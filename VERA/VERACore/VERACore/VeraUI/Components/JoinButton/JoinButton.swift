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
            Text("Join waiting room", bundle: .veraCore)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(JoinRoomButtonStyle(color: color))
        .disabled(roomName.isEmpty)
        .frame(maxWidth: .infinity)
    }
}

struct JoinRoomButtonStyle: ButtonStyle {
    let color: Color

    var cornerRadius: CGFloat = BorderRadius.medium.value

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(VERACommonUIAsset.Colors.uiSystemBackground.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    JoinButton(roomName: .constant(""), color: VERACommonUIAsset.Colors.vGray0.swiftUIColor) {}
    JoinButton(roomName: .constant("Test"), color: VERACommonUIAsset.Colors.vAccent.swiftUIColor) {}
    JoinButton(roomName: .constant("Test"), color: .red) {}
}
