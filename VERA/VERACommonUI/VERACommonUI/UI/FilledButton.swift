//
//  Created by Vonage on 17/11/25.
//

import SwiftUI

/// Layout constants for the filled button style.
private enum FilledButtonConstants {
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

public struct FilledButton: View {
    public let text: Text
    public let image: Image?
    public let onAction: () -> Void

    public init(
        text: Text,
        image: Image? = nil,
        onAction: @escaping () -> Void
    ) {
        self.text = text
        self.image = image
        self.onAction = onAction
    }

    public var body: some View {
        Button {
            onAction()
        } label: {
            HStack {
                if let image {
                    image
                }
                text
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(FilledButtonStyle())
    }
}

struct FilledButtonStyle: ButtonStyle {
    @Environment(\.meetingRoomTheme) private var theme
    var cornerRadius: CGFloat = BorderRadius.medium.value

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, FilledButtonConstants.horizontalPadding)
            .padding(.vertical, FilledButtonConstants.verticalPadding)
            .background(
                theme.primary.opacity(
                    configuration.isPressed ? FilledButtonConstants.pressedOpacity : 1)
            )
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        theme.border,
                        lineWidth: FilledButtonConstants.strokeWidth
                    )
            )
            .animation(.easeOut(duration: FilledButtonConstants.animationDuration), value: configuration.isPressed)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    FilledButton(text: Text("Hello"), image: .init(systemName: "plus")) {}
}
