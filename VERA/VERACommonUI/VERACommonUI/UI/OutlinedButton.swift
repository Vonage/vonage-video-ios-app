//
//  Created by Vonage on 17/11/25.
//

import SwiftUI

/// Layout constants for the outlined button style.
private enum OutlinedButtonConstants {
    /// Horizontal padding inside the button.
    static let horizontalPadding: CGFloat = 24
    /// Vertical padding inside the button.
    static let verticalPadding: CGFloat = 12
    /// Width of the border stroke.
    static let strokeWidth: CGFloat = 1
    /// Opacity when the button is pressed.
    static let pressedOpacity: Double = 0.8
    /// Duration of the press animation.
    static let animationDuration: Double = 0.15
}

public struct OutlinedButton: View {
    public let text: Text
    public let color: Color
    public let image: Image?
    public let isDisabled: Bool
    public let onAction: () -> Void

    public init(
        text: Text,
        color: Color,
        image: Image? = nil,
        isDisabled: Bool = false,
        onAction: @escaping () -> Void
    ) {
        self.text = text
        self.color = color
        self.image = image
        self.isDisabled = isDisabled
        self.onAction = onAction
    }

    public var body: some View {
        Button {
            onAction()
        } label: {
            if let image = image {
                HStack {
                    image
                        .foregroundStyle(color)
                    text
                        .foregroundStyle(color)
                }.frame(maxWidth: .infinity)
            } else {
                text
                    .foregroundStyle(color)
                    .frame(maxWidth: .infinity)
            }
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
            .padding(.horizontal, OutlinedButtonConstants.horizontalPadding)
            .padding(.vertical, OutlinedButtonConstants.verticalPadding)
            .background(.clear)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(color, lineWidth: OutlinedButtonConstants.strokeWidth)
            )
            .opacity(configuration.isPressed ? OutlinedButtonConstants.pressedOpacity : 1)
            .animation(.easeOut(duration: OutlinedButtonConstants.animationDuration), value: configuration.isPressed)
    }
}

#Preview {
    OutlinedButton(
        text: .init("Hello"),
        color: VERACommonUIAsset.SemanticColors.primary.swiftUIColor,
        isDisabled: false
    ) {}
    OutlinedButton(
        text: .init("Hello"),
        color: VERACommonUIAsset.SemanticColors.primary.swiftUIColor,
        image: VERACommonUIAsset.Images.appsSolid.swiftUIImage,
        isDisabled: false
    ) {}
}
