//
//  Created by Vonage on 6/2/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

struct CaptionsButton: View {
    private let state: CaptionsState
    private let action: () -> Void

    init(
        state: CaptionsState,
        action: @escaping () -> Void = {}
    ) {
        self.state = state
        self.action = action
    }

    var body: some View {
        OngoingActivityControlImageButton(
            isActive: state.captionsEnabled,
            image: state.captionsEnabled
                ? VERACommonUIAsset.Images.closedCaptioningOffSolid.swiftUIImage
                : VERACommonUIAsset.Images.closedCaptioningSolid.swiftUIImage,
            action: action)
    }
}

#Preview {
    VStack(spacing: 20) {
        CaptionsButton(state: .enabled)
        CaptionsButton(state: .disabled)
    }
    .padding()
    .background(.white)
}

#Preview {
    VStack(spacing: 20) {
        CaptionsButton(state: .enabled)
        CaptionsButton(state: .disabled)
    }
    .padding()
    .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
    .preferredColorScheme(.dark)
}
