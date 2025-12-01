//
//  Created by Vonage on 14/7/25.
//

import SwiftUI
import VERACommonUI

struct CircularControlButton: View {

    private let isActive: Bool
    private let iconName: String
    private let action: () -> Void

    init(isActive: Bool, iconName: String, action: @escaping () -> Void = {}) {
        self.isActive = isActive
        self.iconName = iconName
        self.action = action
    }

    var body: some View {
        CircularControlImageButton(
            isActive: isActive,
            image: Image(systemName: iconName),
            action: action)
    }
}

struct CircularControlImageButton: View {

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
                .frame(width: 50, height: 50)
                .foregroundColor(.white)
                .background(
                    CircularControlBackground(isActive: isActive)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CircularControlBackground: View {
    let isActive: Bool

    var body: some View {
        #if os(macOS)
            Circle()
                .fill(Material.ultraThinMaterial)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: isActive ? [.white.opacity(0.6), .white.opacity(0.1)] : [.red, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
        #else
            Group {
                if #available(iOS 26.0, *) {
                    glassEffectCircle(
                        isActive ? .clear : VERACommonUIAsset.SemanticColors.error.swiftUIColor.opacity(0.7))
                } else {
                    ZStack {
                        if isActive {
                            Circle()
                                .fill(Material.ultraThinMaterial)
                        } else {
                            Circle()
                                .fill(VERACommonUIAsset.SemanticColors.error.swiftUIColor)
                        }

                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: isActive
                                        ? [.white.opacity(0.6), .white.opacity(0.1)]
                                        : [
                                            VERACommonUIAsset.SemanticColors.error.swiftUIColor,
                                            VERACommonUIAsset.SemanticColors.error.swiftUIColor,
                                        ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    }
                }
            }
        #endif
    }

    #if !os(macOS)
        @available(iOS 26.0, *)
        private func glassEffectCircle(_ color: Color) -> some View {
            Circle()
                .glassEffect(.regular.tint(color))
        }
    #endif
}

#Preview {
    VStack(spacing: 20) {
        CircularControlButton(isActive: true, iconName: "video.fill")
        CircularControlButton(isActive: false, iconName: "video.fill")

        CircularControlButton(isActive: true, iconName: "mic.fill")
        CircularControlButton(isActive: false, iconName: "mic.slash.fill")
    }
    .padding()
    .background(.white)
}

#Preview {
    VStack(spacing: 20) {
        CircularControlButton(isActive: true, iconName: "video.fill")
        CircularControlButton(isActive: false, iconName: "video.fill")

        CircularControlButton(isActive: true, iconName: "mic.fill")
        CircularControlButton(isActive: false, iconName: "mic.slash.fill")
    }
    .padding()
    .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
    .preferredColorScheme(.dark)
}
