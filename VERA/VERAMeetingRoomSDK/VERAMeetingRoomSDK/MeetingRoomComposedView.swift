//
//  Created by Vonage on 16/4/26.
//

import AVKit
import Combine
import SwiftUI
import VERAArchiving
import VERAAudioEffects
import VERABackgroundEffects
import VERACaptions
import VERAChat
import VERACommonUI
import VERADomain
import VERAMeetingRoom
import VERAReactions
import VERAScreenShare
import VERASettings

/// Layout constants for the composed meeting room view.
enum MeetingRoomComposedConstants {
    static var overlayBottomPadding: CGFloat {
        BottomBarConstants.totalHeight + 4
    }
}

/// A self-contained meeting room view with all feature overlays, sheets, and bottom bar buttons.
///
/// This view wraps `MeetingRoomScreen` and applies all feature-specific UI
/// (captions overlay, floating emoji reactions, stats overlay, chat sheet, settings sheet)
/// based on the runtime feature configuration.
///
/// Created internally by ``MeetingRoomBuilder``. Not intended for direct instantiation.
struct MeetingRoomComposedView: View {

    let meetingRoomFactory: MeetingRoomFactory
    @ObservedObject var viewModel: MeetingRoomViewModel

    let container: MeetingRoomSDKContainer
    let enabledFeatures: Set<MeetingRoomFeature>
    let buttonsAssembler: BottomBarButtonsAssembler
    let onAction: (MeetingRoomSDKAction) -> Void
    let alertPresenter: AlertPresenter

    // MARK: - Feature View Models (created during setup)

    // Captions
    let captionsButtonViewModel: CaptionsButtonViewModel?
    let captionsViewModel: CaptionsViewModel?

    // Reactions
    let floatingEmojisOverlayViewModel: FloatingEmojisOverlayViewModel?
    let emojiPickerContainerViewModel: EmojiPickerContainerViewModel?

    // Settings
    let statsOverlayViewModel: StatsOverlayViewModel?

    // MARK: - Sheet/Overlay State

    @State private var showChat = false
    @State private var showPickerView = false
    @State private var showCaptions = false
    @State private var showSettings = false

    var body: some View {
        meetingRoomFactory.make(viewModel: viewModel)
            .modifier(
                ChatSheetModifier(
                    isEnabled: enabledFeatures.contains(.chat),
                    showChat: $showChat,
                    container: container
                )
            )
            .modifier(
                ReactionsOverlayModifier(
                    isEnabled: enabledFeatures.contains(.reactions),
                    showPickerView: $showPickerView,
                    emojiPickerContainerViewModel: emojiPickerContainerViewModel,
                    floatingEmojisOverlayViewModel: floatingEmojisOverlayViewModel,
                    container: container
                )
            )
            .modifier(
                CaptionsOverlayModifier(
                    isEnabled: enabledFeatures.contains(.captions),
                    showCaptions: $showCaptions,
                    captionsButtonViewModel: captionsButtonViewModel,
                    captionsViewModel: captionsViewModel,
                    meetingRoomViewModel: viewModel,
                    container: container
                )
            )
            .modifier(
                SettingsOverlayModifier(
                    isEnabled: enabledFeatures.contains(.settings),
                    showSettings: $showSettings,
                    statsOverlayViewModel: statsOverlayViewModel,
                    container: container
                )
            )
            .onAppear {
                buttonsAssembler.onShowChat = { showChat = true }
                buttonsAssembler.onShowPickerView = { showPickerView = true }
                buttonsAssembler.onShowSettings = { showSettings = true }
            }
    }
}
