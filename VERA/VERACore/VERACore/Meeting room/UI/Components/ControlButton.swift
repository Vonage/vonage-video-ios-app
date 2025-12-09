//
//  Created by Vonage on 23/7/25.
//

import SwiftUI
import VERACommonUI

struct ControlButton: View {
    private let isActive: Bool
    private let iconName: String
    private let action: () -> Void

    init(isActive: Bool, iconName: String, action: @escaping () -> Void = {}) {
        self.isActive = isActive
        self.iconName = iconName
        self.action = action
    }

    var body: some View {
        ControlImageButton(
            isActive: isActive,
            image: Image(systemName: iconName),
            action: action)
    }
}

struct ControlImageButton: View {
    private let isActive: Bool
    private let image: Image
    private let action: () -> Void

    init(isActive: Bool, image: Image, action: @escaping () -> Void = {}) {
        self.isActive = isActive
        self.image = image
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            image
                .font(.title2)
                .foregroundStyle(isActive ? VERACommonUIAsset.SemanticColors.surface.swiftUIColor : .red)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isActive ? VERACommonUIAsset.Colors.vGray4.swiftUIColor : .clear)
                )
                .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .buttonStyle(PlainButtonStyle())
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
