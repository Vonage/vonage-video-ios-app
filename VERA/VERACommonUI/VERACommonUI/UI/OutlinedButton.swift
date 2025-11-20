//
//  Created by Vonage on 17/11/25.
//

import SwiftUI

public struct OutlinedButton: View {
    public let text: Text
    public let color: Color
    public let isDisabled: Bool
    public let onAction: () -> Void

    public init(
        text: Text,
        color: Color,
        isDisabled: Bool,
        onAction: @escaping () -> Void
    ) {
        self.text = text
        self.color = color
        self.isDisabled = isDisabled
        self.onAction = onAction
    }

    public var body: some View {
        Button {
            onAction()
        } label: {
            text
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(OutlinedButtonStyle(color: color))
        .disabled(isDisabled)
        .frame(maxWidth: .infinity)
    }
}

struct OutlinedButtonStyle: ButtonStyle {
    let color: Color

    var cornerRadius: CGFloat = BorderRadius.medium.value

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.clear)
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
    OutlinedButton(
        text: .init("Hello"),
        color: VERACommonUIAsset.SemanticColors.primary.swiftUIColor,
        isDisabled: false,
        onAction: {})
}
