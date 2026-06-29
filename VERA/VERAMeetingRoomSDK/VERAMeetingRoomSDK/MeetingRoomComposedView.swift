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
import VERAVonage

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
    @ObservedObject var pictureInPictureManager: PictureInPictureManager
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
    @State private var showFeedbackForm = false
    @State private var showEffects = false
    @State private var isPictureInPictureBound = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        meetingRoomContent
    }

    private var meetingRoomContent: some View {
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
            .modifier(
                FeedbackFormOverlayModifier(
                    isEnabled: enabledFeatures.contains(.feedback),
                    showFeedbackForm: $showFeedbackForm
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
                buttonsAssembler.onShowPickerView = { showPickerView = true }
                buttonsAssembler.onShowSettings = { showSettings = true }
                buttonsAssembler.onShowFeedbackForm = { showFeedbackForm = true }
                buttonsAssembler.onShowEffects = { showEffects = true }
            }
            .onReceive(selectedEffectPublisher) { _ in
                viewModel.extraButtons = buttonsAssembler.rebuildButtons()
            }
            .task {
                if enabledFeatures.contains(.pictureInPicture) {
                    await bindPictureInPictureIfNeeded()
                }
            }
            .onChange(of: scenePhase) { phase in
                #if !os(macOS)
                    if enabledFeatures.contains(.pictureInPicture), phase == .background {
                        pictureInPictureManager.requestPictureInPicture()
                    }
                #endif
            }
    }

    private func bindPictureInPictureIfNeeded() async {
        #if !os(macOS)
            while viewModel.currentCall == nil {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
            }

            guard !isPictureInPictureBound,
                let call = viewModel.currentCall as? VonageCall
            else { return }

            PictureInPictureBinder.bind(
                manager: pictureInPictureManager,
                call: call
            )
            isPictureInPictureBound = true
        #endif
    }

    /// Publisher that emits when the selected video effect changes (skipping the initial value).
    private var selectedEffectPublisher: AnyPublisher<VideoEffect, Never> {
        guard let vm = buttonsAssembler.videoEffectsViewModel else {
            return Empty().eraseToAnyPublisher()
        }
        return vm.$selectedEffect.dropFirst().eraseToAnyPublisher()
    }
}
