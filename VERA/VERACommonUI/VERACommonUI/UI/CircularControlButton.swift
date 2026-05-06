//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

/// Layout constants for the circular control button.
private enum CircularControlButtonConstants {
    /// Diameter of the circular button.
    static let buttonSize: CGFloat = 50
    /// Width of the gradient border stroke.
    static let strokeWidth: CGFloat = 1.2
    /// Active-state gradient start opacity.
    static let activeGradientStartOpacity: Double = 0.6
    /// Active-state gradient end opacity.
    static let activeGradientEndOpacity: Double = 0.1
    /// Inactive-state error tint opacity.
    static let errorTintOpacity: Double = 0.7
}

public struct CircularControlButton: View {

    private let isActive: Bool
    private let iconName: String
    private let action: () -> Void

    public init(isActive: Bool, iconName: String, action: @escaping () -> Void = {}) {
        self.isActive = isActive
        self.iconName = iconName
        self.action = action
    }

    public var body: some View {
        CircularControlImageButton(
            isActive: isActive,
            image: Image(systemName: iconName),
            action: action)
    }
}

public struct CircularControlImageButton: View {

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
                .frame(
                    width: CircularControlButtonConstants.buttonSize,
                    height: CircularControlButtonConstants.buttonSize
                )
                .foregroundColor(.white)
                .background(
                    CircularControlBackground(isActive: isActive)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CircularControlBackground: View {
    @Environment(\.meetingRoomTheme) private var theme
    let isActive: Bool

    var body: some View {
        #if os(macOS)
            Circle()
                .fill(Material.ultraThinMaterial)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: isActive
                                    ? [
                                        .white.opacity(CircularControlButtonConstants.activeGradientStartOpacity),
                                        .white.opacity(CircularControlButtonConstants.activeGradientEndOpacity),
                                    ] : [.red, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: CircularControlButtonConstants.strokeWidth
                        )
                )
        #else
            Group {
                if #available(iOS 26.0, *) {
                    glassEffectCircle(
                        isActive
                            ? .clear
                            : theme.error
                                .opacity(CircularControlButtonConstants.errorTintOpacity))
                } else {
                    ZStack {
                        if isActive {
                            Circle()
                                .fill(Material.ultraThinMaterial)
                        } else {
                            Circle()
                                .fill(theme.error)
                        }

                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: isActive
                                        ? [
                                            .white.opacity(
                                                CircularControlButtonConstants.activeGradientStartOpacity),
                                            .white.opacity(
                                                CircularControlButtonConstants.activeGradientEndOpacity),
                                        ]
                                        : [
                                            theme.error,
                                            theme.error,
                                        ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: CircularControlButtonConstants.strokeWidth
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
