//
//  Created by Vonage on 13/1/26.
//

import SwiftUI
import VERACommonUI

public struct ArchiveButtonState {
    public let isArchiving: Bool

    public init(isArchiving: Bool) {
        self.isArchiving = isArchiving
    }

    public static let initial = ArchiveButtonState(isArchiving: false)
}

struct ArchiveButton: View {
    private let state: ArchiveButtonState
    private let action: () -> Void

    init(
        state: ArchiveButtonState,
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
        ArchiveButton(state: .init(isArchiving: true))
        ArchiveButton(state: .init(isArchiving: false))
    }
    .padding()
    .background(.white)
}

#Preview {
    VStack(spacing: 20) {
        ArchiveButton(state: .init(isArchiving: true))
        ArchiveButton(state: .init(isArchiving: false))
    }
    .padding()
    .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
    .preferredColorScheme(.dark)
}
