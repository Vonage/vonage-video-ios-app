//
//  Created by Vonage on 17/10/26.
//

import SwiftUI
import VERACommonUI

/// Full-bleed sheet showing the screen-share participant's view.
///
/// The participant's `onAppear`/`onDisappear` callbacks are wired to the
/// view's lifecycle so the host subscribes to the share's video only while it
/// is visible.
public struct OnTheGoSharedContentSheet: View {

    @Environment(\.meetingRoomTheme) private var theme

    @Bindable private var viewModel: OnTheGoViewModel

    public init(viewModel: OnTheGoViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            if let participant = viewModel.snapshot.screenShareParticipant, let view = participant.view {
                view
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear(perform: participant.onAppear ?? {})
                    .onDisappear(perform: participant.onDisappear ?? {})
            } else {
                theme.videoBackground
            }

            Button("Done".localized, action: viewModel.dismissSharedContent)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(12)
                .accessibilityIdentifier(OnTheGoAccessibilityID.sharedContentDoneButton)
        }
        .background(theme.videoBackground)
        .accessibilityIdentifier(OnTheGoAccessibilityID.sharedContentSheet)
    }
}
