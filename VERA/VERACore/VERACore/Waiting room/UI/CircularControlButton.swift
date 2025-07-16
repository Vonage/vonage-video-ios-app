//
//  Created by Vonage on 14/7/25.
//

import SwiftUI

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
        Button(action: action) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(isActive ? .white : .red)
                .frame(width: 50, height: 50)
                .background(
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
                )
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .buttonStyle(PlainButtonStyle())
    }
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
    .background(.videoBackground)
    .preferredColorScheme(.dark)
}
