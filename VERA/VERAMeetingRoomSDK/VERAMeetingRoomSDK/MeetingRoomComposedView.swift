//
//  Created by Vonage on 16/4/26.
//

import AVKit
import Combine
import SwiftUI
import VERAAudioEffects
import VERAArchiving
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
private enum MeetingRoomComposedConstants {
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
            .modifier(ChatSheetModifier(
                isEnabled: enabledFeatures.contains(.chat),
                showChat: $showChat,
                container: container
            ))
            .modifier(ReactionsOverlayModifier(
                isEnabled: enabledFeatures.contains(.reactions),
                showPickerView: $showPickerView,
                emojiPickerContainerViewModel: emojiPickerContainerViewModel,
                floatingEmojisOverlayViewModel: floatingEmojisOverlayViewModel,
                container: container
            ))
            .modifier(CaptionsOverlayModifier(
                isEnabled: enabledFeatures.contains(.captions),
                showCaptions: $showCaptions,
                captionsButtonViewModel: captionsButtonViewModel,
                captionsViewModel: captionsViewModel,
                meetingRoomViewModel: viewModel,
                container: container
            ))
            .modifier(SettingsOverlayModifier(
                isEnabled: enabledFeatures.contains(.settings),
                showSettings: $showSettings,
                statsOverlayViewModel: statsOverlayViewModel,
                container: container
            ))
            .onAppear {
                buttonsAssembler.onShowChat = { showChat = true }
                buttonsAssembler.onShowPickerView = { showPickerView = true }
                buttonsAssembler.onShowSettings = { showSettings = true }
            }
    }
}

// MARK: - Chat Sheet Modifier

private struct ChatSheetModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var showChat: Bool
    let container: MeetingRoomSDKContainer

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .sheet(
                    isPresented: $showChat,
                    onDismiss: {
                        container.chatBadgeButtonViewModel.chatDidClose()
                    }
                ) {
                    let result = container.chatFactory.make {
                        showChat = false
                    }
                    result.view
                }
        } else {
            content
        }
    }
}

// MARK: - Reactions Overlay Modifier

private struct ReactionsOverlayModifier: ViewModifier {
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

// MARK: - Captions Overlay Modifier

private struct CaptionsOverlayModifier: ViewModifier {
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

// MARK: - Settings Overlay Modifier

private struct SettingsOverlayModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var showSettings: Bool
    let statsOverlayViewModel: StatsOverlayViewModel?
    let container: MeetingRoomSDKContainer

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .sheet(isPresented: $showSettings) {
                    container.settingsFactory.makeMeetingRoomSettingsView()
                        .presentationDetents([.large])
                }
                .overlay {
                    if let statsViewModel = statsOverlayViewModel {
                        container.settingsFactory.makeStatsOverlayView(viewModel: statsViewModel)
                    }
                }
        } else {
            content
        }
    }
}
