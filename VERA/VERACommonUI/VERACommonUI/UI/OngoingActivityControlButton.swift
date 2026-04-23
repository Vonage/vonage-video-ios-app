//
//  Created by Vonage on 13/1/26.
//

import SwiftUI

/// Layout constants for the ongoing activity control button.
private enum OngoingActivityControlButtonConstants {
    /// Diameter of the circular button.
    static let buttonSize: CGFloat = 50
    /// Duration of the active-state toggle animation.
    static let animationDuration: Double = 0.2
}

public struct OngoingActivityControlButton: View {
    private let isActive: Bool
    private let iconName: String
    private let action: () -> Void

    public init(isActive: Bool, iconName: String, action: @escaping () -> Void = {}) {
        self.isActive = isActive
        self.iconName = iconName
        self.action = action
    }

    public var body: some View {
        OngoingActivityControlImageButton(
            isActive: isActive,
            image: Image(systemName: iconName),
            action: action)
    }
}

public struct OngoingActivityControlImageButton: View {
    @Environment(\.meetingRoomTheme) private var theme
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
                .foregroundStyle(theme.surface)
                .frame(
                    width: OngoingActivityControlButtonConstants.buttonSize,
                    height: OngoingActivityControlButtonConstants.buttonSize
                )
                .background(
                    Circle()
                        .fill(
                            isActive
                                ? theme.vGray2
                                : theme.vGray4)
                )
                .animation(
                    .easeInOut(duration: OngoingActivityControlButtonConstants.animationDuration),
                    value: isActive
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        OngoingActivityControlButton(isActive: true, iconName: "video.fill")
        OngoingActivityControlButton(isActive: false, iconName: "video.slash.fill")
    }
    .padding()
    .background(.white)
}

#Preview {
    VStack(spacing: 20) {
        OngoingActivityControlButton(isActive: true, iconName: "video.fill")
        OngoingActivityControlButton(isActive: false, iconName: "video.fill")
    }
    .padding()
    .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
    .preferredColorScheme(.dark)
}
