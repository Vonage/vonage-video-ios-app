//
//  Created by Vonage on 17/11/25.
//

import SwiftUI

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
    FilledButton(text: Text("Hello"), image: .init(systemName: "plus"), onAction: {})
}
