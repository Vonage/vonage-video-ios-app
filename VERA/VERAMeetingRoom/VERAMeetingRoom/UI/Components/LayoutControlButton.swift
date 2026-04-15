//
//  Created by Vonage on 12/8/25.
//

import SwiftUI
import VERACommonUI
import VERADomain

/// Layout constants for the layout toggle button.
private enum LayoutControlButtonConstants {
    /// Diameter of the circular button.
    static let buttonSize: CGFloat = 50
    /// Scale factor for the insertion transition.
    static let insertionScale: CGFloat = 0.8
    /// Scale factor for the removal transition.
    static let removalScale: CGFloat = 1.2
    /// Spring animation response for layout changes.
    static let springResponse: Double = 0.4
    /// Spring animation damping fraction.
    static let springDamping: Double = 0.8
}

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
                .frame(
                    width: LayoutControlButtonConstants.buttonSize,
                    height: LayoutControlButtonConstants.buttonSize
                )
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
                VERACommonUIAsset.Images.layout2Solid.swiftUIImage
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(
                                with: .scale(scale: LayoutControlButtonConstants.insertionScale)),
                            removal: .opacity.combined(
                                with: .scale(scale: LayoutControlButtonConstants.removalScale))
                        ))
            } else {
                VERACommonUIAsset.Images.appsSolid.swiftUIImage
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(
                                with: .scale(scale: LayoutControlButtonConstants.insertionScale)),
                            removal: .opacity.combined(
                                with: .scale(scale: LayoutControlButtonConstants.removalScale))
                        ))
            }
        }
        .animation(
            .spring(
                response: LayoutControlButtonConstants.springResponse,
                dampingFraction: LayoutControlButtonConstants.springDamping
            ), value: layout
        )
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
