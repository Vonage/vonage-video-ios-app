//
//  Created by Vonage on 30/7/25.
//

import SwiftUI

struct ReenterRoomButton: View {
    let onReenter: () -> Void

    var body: some View {
        Button {
            onReenter()
        } label: {
            Text("Re-enter", bundle: .veraCore)
        }
        .buttonStyle(ReenterRoomButtonStyle())
    }
}

struct ReenterRoomButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = 20

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .tint(.accentBlue)
            .foregroundColor(.blue)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(.uiSystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.blue, lineWidth: 1.2)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ReenterRoomButton() {}
    ReenterRoomButton() {}
    ReenterRoomButton() {}
}
