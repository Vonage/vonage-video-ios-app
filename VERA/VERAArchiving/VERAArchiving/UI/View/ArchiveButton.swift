//
//  Created by Vonage on 13/1/26.
//

import SwiftUI
import VERACommonUI
import VERADomain

struct ArchiveButton: View {
    private let kind: ArchiveKind
    private let state: ArchivingState
    private let action: () -> Void

    init(
        kind: ArchiveKind = .recording,
        state: ArchivingState,
        action: @escaping () -> Void = {}
    ) {
        self.kind = kind
        self.state = state
        self.action = action
    }

    var body: some View {
        OngoingActivityControlImageButton(
            isActive: state.isArchiving,
            image: kind.bottomBarImage(for: state),
            action: action
        )
        .accessibilityIdentifier(kind.bottomBarAccessibilityIdentifier(for: state))
    }
}

#Preview {
    VStack(spacing: 20) {
        ArchiveButton(state: .archiving(""))
        ArchiveButton(state: .idle)
        ArchiveButton(kind: .transcription, state: .archiving(""))
        ArchiveButton(kind: .transcription, state: .idle)
    }
    .padding()
    .background(.white)
}

#Preview {
    VStack(spacing: 20) {
        ArchiveButton(state: .archiving(""))
        ArchiveButton(state: .idle)
        ArchiveButton(kind: .transcription, state: .archiving(""))
        ArchiveButton(kind: .transcription, state: .idle)
    }
    .padding()
    .background(VERACommonUIAsset.Colors.videoBackground.swiftUIColor)
    .preferredColorScheme(.dark)
}
