//
//  Created by Vonage on 21/04/2026.
//

import Combine
import SwiftUI
import VERACaptions
import VERADomain
import VERAMeetingRoom

// MARK: - Captions Overlay Modifier

struct CaptionsOverlayModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var showCaptions: Bool
    let captionsButtonViewModel: CaptionsButtonViewModel?
    let captionsViewModel: CaptionsViewModel?
    let meetingRoomViewModel: MeetingRoomViewModel
    let container: MeetingRoomSDKContainer

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .onChange(of: captionsButtonViewModel?.state, initial: true) { _, state in
                    guard let state else { return }
                    showCaptions = state.captionsEnabled
                }
                .onChange(of: captionsButtonViewModel?.toast) { _, toast in
                    guard let toast else { return }
                    meetingRoomViewModel.toast = toast
                }
                .dismissibleOverlay(
                    isPresented: $showCaptions,
                    alignment: .bottom,
                    edgePadding: MeetingRoomComposedConstants.overlayBottomPadding,
                    allowsHitTesting: false
                ) {
                    if let captionsViewModel {
                        container.captionsFactory.makeCaptionsView(viewModel: captionsViewModel)
                    }
                }
        } else {
            content
        }
    }
}
