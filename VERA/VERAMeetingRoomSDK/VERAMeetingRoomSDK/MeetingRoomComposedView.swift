//
//  Created by Vonage on 16/4/26.
//

import AVKit
import SwiftUI
import VERAAudioEffects
import VERABackgroundEffects
import VERACaptions
import VERAChat
import VERACommonUI
import VERADomain
import VERAFeedback
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
    @State private var showReactions = false
    @State private var showCaptions = false
    @State private var showSettings = false
    @State private var showFeedbackForm = false
    @State private var showEffects = false

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
                    showPickerView: $showReactions,
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
            .modifier(
                FeedbackFormOverlayModifier(
                    isEnabled: enabledFeatures.contains(.feedback),
                    showFeedbackForm: $showFeedbackForm,
                    container: container
                )
            )
            .modifier(
                BackgroundEffectsOverlayModifier(
                    isEnabled: enabledFeatures.contains(.backgroundEffects),
                    showEffects: $showEffects,
                    videoEffectsViewModel: buttonsAssembler.videoEffectsViewModel
                )
            )
            .onAppear {
                buttonsAssembler.onShowChat = { showChat = true }
                buttonsAssembler.onShowReactions = { showReactions.toggle() }
                buttonsAssembler.onShowSettings = { showSettings = true }
                buttonsAssembler.onShowFeedbackForm = { showFeedbackForm = true }
                buttonsAssembler.onShowEffects = { showEffects = true }
            }
            .onChange(of: showReactions) { isPresented in
                buttonsAssembler.setReactionsPickerPresented(isPresented)
            }
            .onChange(of: showChat) { isPresented in
                buttonsAssembler.setChatPresented(isPresented)
            }
            .onChange(of: showSettings) { isPresented in
                buttonsAssembler.setSettingsPresented(isPresented)
            }
            .onChange(of: showEffects) { isPresented in
                buttonsAssembler.setEffectsPresented(isPresented)
            }
            .onChange(of: showFeedbackForm) { isPresented in
                buttonsAssembler.setFeedbackFormPresented(isPresented)
            }
    }
}
