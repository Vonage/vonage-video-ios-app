//
//  Created by Vonage on 13/1/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

struct ArchiveButton: View {
    private let state: ArchivingState
    private let action: () -> Void

    init(
        state: ArchivingState,
        action: @escaping () -> Void = {}
    ) {
        self.state = state
        self.action = action
    }

    var body: some View {
        OngoingActivityControlImageButton(
            isActive: state.isArchiving,
            image: state.isArchiving
                ? VERACommonUIAsset.Images.radioChecked2Line.swiftUIImage
                : VERACommonUIAsset.Images.radioChecked2Solid.swiftUIImage,
            action: action)
    }
}

#Preview {
    VStack(spacing: 20) {
        ArchiveButton(state: .archiving(""))
        ArchiveButton(state: .idle)
    }
    .padding()
    .background(.white)
}

#Preview {
    VStack(spacing: 20) {
        ArchiveButton(state: .archiving(""))
        ArchiveButton(state: .idle)
    }
    .padding()
    .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
    .preferredColorScheme(.dark)
}
