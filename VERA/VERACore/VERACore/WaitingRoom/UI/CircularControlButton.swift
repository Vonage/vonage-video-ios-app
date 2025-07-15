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
                .foregroundStyle(isActive ? .videoBackground : .red)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isActive ? .red : .clear)
                        .overlay(
                            Circle()
                                .stroke(isActive ? .clear : .red, lineWidth: 2)
                        )
                )
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
