//
//  Created by Vonage on 13/1/26.
//

import SwiftUI

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
                .foregroundStyle(VERACommonUIAsset.SemanticColors.surface.swiftUIColor)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(
                            isActive
                                ? VERACommonUIAsset.Colors.vGray2.swiftUIColor
                                : VERACommonUIAsset.Colors.vGray4.swiftUIColor)
                )
                .animation(.easeInOut(duration: 0.2), value: isActive)
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
