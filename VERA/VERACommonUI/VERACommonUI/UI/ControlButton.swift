//
//  Created by Vonage on 23/7/25.
//

import SwiftUI

/// Layout constants shared by control button variants.
private enum ControlButtonConstants {
    /// Diameter of the circular button.
    static let buttonSize: CGFloat = 50
    /// Duration of the active-state toggle animation.
    static let animationDuration: Double = 0.2
}

public struct ControlButton: View {
    private let isActive: Bool
    private let iconName: String
    private let action: () -> Void

    public init(isActive: Bool, iconName: String, action: @escaping () -> Void = {}) {
        self.isActive = isActive
        self.iconName = iconName
        self.action = action
    }

    public var body: some View {
        ControlImageButton(
            isActive: isActive,
            image: Image(systemName: iconName),
            action: action)
    }
}

public struct ControlImageButton: View {
    private let isActive: Bool
    private let image: Image
    private let action: () -> Void

    public init(isActive: Bool, image: Image, action: @escaping () -> Void = {}) {
        self.isActive = isActive
        self.image = image
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            image
                .font(.title2)
                .foregroundStyle(isActive ? VERACommonUIAsset.SemanticColors.surface.swiftUIColor : .red)
                .frame(width: ControlButtonConstants.buttonSize, height: ControlButtonConstants.buttonSize)
                .background(
                    Circle()
                        .fill(isActive ? VERACommonUIAsset.Colors.vGray4.swiftUIColor : .clear)
                )
                .animation(.easeInOut(duration: ControlButtonConstants.animationDuration), value: isActive)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

public struct ButtonImage: View {
    private let image: Image

    public init(image: Image) {
        self.image = image
    }

    public var body: some View {
        image
            .font(.title2)
            .foregroundStyle(VERACommonUIAsset.SemanticColors.surface.swiftUIColor)
            .frame(width: ControlButtonConstants.buttonSize, height: ControlButtonConstants.buttonSize)
            .background(
                Circle()
                    .fill(VERACommonUIAsset.Colors.vGray4.swiftUIColor)
            )
    }
}

#Preview {
    VStack(spacing: 20) {
        ControlButton(isActive: true, iconName: "video.fill")
        ControlButton(isActive: false, iconName: "video.slash.fill")

        ControlButton(isActive: true, iconName: "mic.fill")
        ControlButton(isActive: false, iconName: "mic.slash.fill")
    }
    .padding()
    .background(.white)
}

#Preview {
    VStack(spacing: 20) {
        ControlButton(isActive: true, iconName: "video.fill")
        ControlButton(isActive: false, iconName: "video.fill")

        ControlButton(isActive: true, iconName: "mic.fill")
        ControlButton(isActive: false, iconName: "mic.slash.fill")
    }
    .padding()
    .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
    .preferredColorScheme(.dark)
}
