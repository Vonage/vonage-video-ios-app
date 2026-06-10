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
    public let expandsToFillWidth: Bool
    public let fillColor: Color
    public let onAction: () -> Void

    public init(
        text: Text,
        color: Color,
        image: Image? = nil,
        isDisabled: Bool = false,
        expandsToFillWidth: Bool = true,
        fillColor: Color = .clear,
        onAction: @escaping () -> Void
    ) {
        self.text = text
        self.color = color
        self.image = image
        self.isDisabled = isDisabled
        self.expandsToFillWidth = expandsToFillWidth
        self.fillColor = fillColor
        self.onAction = onAction
    }

    public var body: some View {
        Button {
            onAction()
        } label: {
            labelContent
        }
        .buttonStyle(OutlinedButtonStyle(color: color, fillColor: fillColor))
        .disabled(isDisabled)
        .modifier(HorizontalExpansionModifier(isEnabled: expandsToFillWidth))
    }

    @ViewBuilder
    private var labelContent: some View {
        if let image = image {
            HStack {
                image
                    .foregroundStyle(color)
                text
                    .foregroundStyle(color)
            }
            .modifier(HorizontalExpansionModifier(isEnabled: expandsToFillWidth))
        } else {
            text
                .foregroundStyle(color)
                .modifier(HorizontalExpansionModifier(isEnabled: expandsToFillWidth))
        }
    }
}

private struct HorizontalExpansionModifier: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if isEnabled {
            content.frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}

struct OutlinedButtonStyle: ButtonStyle {
    let color: Color
    let fillColor: Color

    var cornerRadius: CGFloat = BorderRadius.medium.value

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, OutlinedButtonConstants.horizontalPadding)
            .padding(.vertical, OutlinedButtonConstants.verticalPadding)
            .background(fillColor)
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
