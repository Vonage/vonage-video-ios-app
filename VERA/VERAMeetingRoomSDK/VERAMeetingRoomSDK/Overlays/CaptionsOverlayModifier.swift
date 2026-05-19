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

    private var captionsStatePublisher: AnyPublisher<CaptionsState, Never> {
        captionsButtonViewModel?.$state
            .eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
    }

    private var captionsToastPublisher: AnyPublisher<ToastItem, Never> {
        captionsButtonViewModel?.$toast
            .compactMap { $0 }
            .eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
    }

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .onReceive(captionsStatePublisher) { state in
                    showCaptions = state.captionsEnabled
                }
                .onReceive(captionsToastPublisher) { toast in
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
