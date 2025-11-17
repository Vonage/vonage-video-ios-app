//
//  Created by Vonage on 7/8/25.
//

import SwiftUI
import VERACommonUI

struct NewRoomButton: View {

    let onHandleNewRoom: () -> Void

    var body: some View {
        Button {
            onHandleNewRoom()
        } label: {
            HStack {
                VERACommonUIAsset.Images.plusLine.swiftUIImage
                Text("Create room", bundle: .veraCore)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(NewRoomButtonStyle())
    }
}

struct NewRoomButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                VERACommonUIAsset.SemanticColors.primary.swiftUIColor.opacity(configuration.isPressed ? 0.8 : 1)
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(VERACommonUIAsset.SemanticColors.border.swiftUIColor, lineWidth: 1)
            )
            .shadow(radius: 5)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    NewRoomButton {}
}
