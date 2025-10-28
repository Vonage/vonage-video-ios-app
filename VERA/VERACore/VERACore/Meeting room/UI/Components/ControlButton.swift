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
        Button(action: action) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(isActive ? VERACommonUIAsset.uiSystemBackground.swiftUIColor : .red)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isActive ? VERACommonUIAsset.vGray4.swiftUIColor : .clear)
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
    .background(VERACommonUIAsset.videoBackground.swiftUIColor)
    .preferredColorScheme(.dark)
}
