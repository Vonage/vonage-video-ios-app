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
                .foregroundStyle(isActive ? .white : .red)
                .frame(width: 50, height: 50)
                .background(
                    CircularControlBackground(isActive: isActive)
                )
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .animation(.easeInOut(duration: 0.2), value: isActive)
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
                    glassEffectCircle()
                } else {
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
                }
            }
        #endif
    }

    #if !os(macOS)
        @available(iOS 26.0, *)
        private func glassEffectCircle() -> some View {
            Circle()
                .glassEffect()
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
