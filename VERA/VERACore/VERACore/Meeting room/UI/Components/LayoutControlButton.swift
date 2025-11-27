//
//  Created by Vonage on 12/8/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

struct LayoutControlButton: View {
    private let layout: MeetingRoomLayout
    private let action: () -> Void

    init(layout: MeetingRoomLayout, action: @escaping () -> Void = {}) {
        self.layout = layout
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            LayoutImage(layout: layout)
                .font(.title2)
                .foregroundStyle(VERACommonUIAsset.SemanticColors.surface.swiftUIColor)
                .frame(width: 50, height: 50)
                .background(Circle().fill(VERACommonUIAsset.Colors.vGray4.swiftUIColor))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LayoutImage: View {
    let layout: MeetingRoomLayout

    var body: some View {
        ZStack {
            if layout == .activeSpeaker {
                VERACommonUIAsset.Images.bringToFrontSolid.swiftUIImage
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.8)),
                            removal: .opacity.combined(with: .scale(scale: 1.2))
                        ))
            } else {
                VERACommonUIAsset.Images.appsSolid.swiftUIImage
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.8)),
                            removal: .opacity.combined(with: .scale(scale: 1.2))
                        ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: layout)
    }
}

#Preview {
    VStack(spacing: 20) {
        LayoutControlButton(layout: .activeSpeaker)
        LayoutControlButton(layout: .grid)
    }
    .padding()
    .background(.white)
}

#Preview {
    VStack(spacing: 20) {
        LayoutControlButton(layout: .activeSpeaker)
        LayoutControlButton(layout: .grid)
    }
    .padding()
    .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
    .preferredColorScheme(.dark)
}
