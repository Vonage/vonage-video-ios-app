//
//  Created by Vonage on 21/04/2026.
//

import SwiftUI
import VERAReactions

// MARK: - Reactions Overlay Modifier

struct ReactionsOverlayModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var showPickerView: Bool
    let emojiPickerContainerViewModel: EmojiPickerContainerViewModel?
    let floatingEmojisOverlayViewModel: FloatingEmojisOverlayViewModel?
    let container: MeetingRoomSDKContainer

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .dismissibleOverlay(
                    isPresented: $showPickerView,
                    alignment: .bottom,
                    edgePadding: MeetingRoomComposedConstants.overlayBottomPadding
                ) {
                    if let viewModel = emojiPickerContainerViewModel {
                        EmojiPickerViewContainer(viewModel: viewModel)
                    }
                }
                .overlay {
                    if let viewModel = floatingEmojisOverlayViewModel {
                        FloatingEmojisOverlayView(viewModel: viewModel)
                    }
                }
        } else {
            content
        }
    }
}
