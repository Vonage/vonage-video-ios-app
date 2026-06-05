//
//  Created by Vonage on 16/4/26.
//

import Combine
import Foundation
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

/// Assembles bottom bar buttons based on runtime feature configuration.
///
/// Replaces the scattered `#if FEATURE_ENABLED` compilation conditions
/// previously used in `DependencyContainer+BottomBarButtons` and `VERAApp.getBottomBarButtons()`.
@MainActor
final class BottomBarButtonsAssembler {

    private let container: MeetingRoomSDKContainer
    private let enabledFeatures: Set<MeetingRoomFeature>

    // Feature view models created during meeting room setup
    var backgroundBlurButtonViewModel: BackgroundBlurButtonViewModel?
    var archiveButtonViewModel: ArchiveButtonViewModel?
    var captionsButtonViewModel: CaptionsButtonViewModel?
    var emojiButtonContainerViewModel: EmojiButtonContainerViewModel?
    var meetingNoiseSuppressionButtonViewModel: MeetingNoiseSuppressionViewModel?

    // Bindings for sheet/overlay presentation
    var onShowChat: (() -> Void)?
    var onShowPickerView: (() -> Void)?
    var onShowSettings: (() -> Void)?

    init(
        container: MeetingRoomSDKContainer,
        enabledFeatures: Set<MeetingRoomFeature>
    ) {
        self.container = container
        self.enabledFeatures = enabledFeatures
    }

    /// Builds the array of extra bottom bar buttons based on enabled features.
    ///
    /// Called by `MeetingRoomViewModel` via `getExternalButtons` closure
    /// each time the meeting room state changes (e.g., archiving state updates).
    ///
    /// - Parameter state: Current meeting room button state (e.g., archiving state).
    /// - Returns: Array of feature buttons to display in the bottom bar.
    func buildButtons(_ state: MeetingRoomButtonsState) -> [BottomBarButton] {
        var buttons: [BottomBarButton] = []

        if enabledFeatures.contains(.chat) {
            buttons.append(makeChatButton())
        }

        if enabledFeatures.contains(.backgroundEffects),
            let viewModel = backgroundBlurButtonViewModel
        {
            buttons.append(makeBackgroundEffectsButton(viewModel))
        }

        if enabledFeatures.contains(.archiving),
            let viewModel = archiveButtonViewModel
        {
            buttons.append(makeArchiveButton(viewModel, state))
        }

        if enabledFeatures.contains(.captions),
            let viewModel = captionsButtonViewModel
        {
            buttons.append(makeCaptionsButton(viewModel))
        }

        if enabledFeatures.contains(.reactions),
            let viewModel = emojiButtonContainerViewModel
        {
            buttons.append(makeReactionsButton(viewModel))
        }

        if enabledFeatures.contains(.screenShare) {
            buttons.append(makeScreenShareButton())
        }

        if enabledFeatures.contains(.settings) {
            buttons.append(makeSettingsButton())
        }

        if enabledFeatures.contains(.audioEffects) {
            buttons.append(makeAudioEffectsButton())
        }

        return buttons
    }

    // MARK: - Individual Button Builders

    private func makeChatButton() -> BottomBarButton {
        let viewModel = container.chatBadgeButtonViewModel
        return .init(
            label: String(localized: "Chat"),
            image: VERACommonUIAsset.Images.chat2Solid.swiftUIImage,
            onTap: { [weak self] in
                viewModel.chatDidOpen()
                self?.onShowChat?()
            },
            content: {
                ChatBadgeComponentButton(
                    viewModel: viewModel,
                    onShowChat: { [weak self] in
                        viewModel.chatDidOpen()
                        self?.onShowChat?()
                    })
            })
    }

    private func makeBackgroundEffectsButton(
        _ viewModel: BackgroundBlurButtonViewModel
    ) -> BottomBarButton {
        let button = container.backgroundBlurFactory.makeMeetingBlurButton(viewModel: viewModel)
        return .init(
            label: String(localized: "Blur"),
            image: viewModel.currentVideoEffect.image,
            onTap: {
                viewModel.onTap()
            },
            content: {
                button
            })
    }

    private func makeArchiveButton(
        _ viewModel: ArchiveButtonViewModel,
        _ state: MeetingRoomButtonsState
    ) -> BottomBarButton {
        let button = container.archivingFactory.makeArchivingButton(viewModel: viewModel)
        return .init(
            label: state.archivingState.isArchiving
                ? String(localized: "Stop Recording") : String(localized: "Start Recording"),
            accessibilityIdentifier: state.archivingState.isArchiving
                ? ArchivingAccessibilityID.stopRecordingButton : ArchivingAccessibilityID.startRecordingButton,
            image: VERACommonUIAsset.Images.radioChecked2Line.swiftUIImage,
            onTap: viewModel.onTap,
            content: {
                button
            })
    }

    private func makeCaptionsButton(
        _ viewModel: CaptionsButtonViewModel
    ) -> BottomBarButton {
        let button = container.captionsFactory.makeCaptionsButton(viewModel: viewModel)
        return .init(
            label: String(localized: "Captions"),
            image: viewModel.state.captionsEnabled
                ? VERACommonUIAsset.Images.closedCaptioningOffSolid.swiftUIImage
                : VERACommonUIAsset.Images.closedCaptioningSolid.swiftUIImage,
            onTap: {
                viewModel.onTap()
            },
            content: {
                button
            })
    }

    private func makeReactionsButton(
        _ viewModel: EmojiButtonContainerViewModel
    ) -> BottomBarButton {
        let emojiButtonContainer = container.reactionsFactory.makeEmojiButtonContainer(
            viewModel: viewModel)
        return .init(
            label: String(localized: "Reactions"),
            image: VERACommonUIAsset.Images.emojiSolid.swiftUIImage,
            onTap: { [weak self] in
                self?.onShowPickerView?()
            },
            content: {
                emojiButtonContainer
            }
        )
    }

    private func makeScreenShareButton() -> BottomBarButton {
        let actionTrigger = PassthroughSubject<Void, Never>()
        let extensionId =
            container.broadcastExtensionBundleId
            ?? (Bundle.main.bundleIdentifier ?? "com.vonage.VERA") + ".BroadcastExtension"
        let button = ScreenShareFactory.make(broadcastExtensionBundleId: extensionId)
        return .init(
            label: String(localized: "Share Screen"),
            image: VERACommonUIAsset.Images.screenShareSolid.swiftUIImage,
            onTap: {
                actionTrigger.send()
            },
            content: {
                button
            }
        ) {
            BroadcastPickerRepresentable(
                preferredExtension: extensionId,
                actionTrigger: actionTrigger
            )
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .allowsHitTesting(false)
        }
    }

    private func makeSettingsButton() -> BottomBarButton {
        let button = container.settingsFactory.makeMeetingRoomButton { [weak self] in
            self?.onShowSettings?()
        }
        return .init(
            label: String(localized: "Settings"),
            image: VERACommonUIAsset.Images.gearSolid.swiftUIImage,
            onTap: { [weak self] in
                self?.onShowSettings?()
            },
            content: {
                button
            }
        )
    }

    private func makeAudioEffectsButton() -> BottomBarButton {
        let viewModel: MeetingNoiseSuppressionViewModel
        if let existing = meetingNoiseSuppressionButtonViewModel {
            viewModel = existing
        } else {
            viewModel = container.audioEffectsFactory.makeMeetingNoiseSuppressionButton().viewModel
            meetingNoiseSuppressionButtonViewModel = viewModel
        }
        let view = container.audioEffectsFactory.makeMeetingNoiseSuppressionButton(viewModel: viewModel)
        return .init(
            label: String(localized: "Noise Suppression"),
            image: VERACommonUIAsset.Images.noiseSuppressionDisabled.swiftUIImage,
            onTap: {
                viewModel.onTap()
            },
            content: {
                view
            }
        )
    }


    func cleanUp() {
        backgroundBlurButtonViewModel = nil
        archiveButtonViewModel = nil
        captionsButtonViewModel = nil
        emojiButtonContainerViewModel = nil
        meetingNoiseSuppressionButtonViewModel = nil

        onShowChat = nil
        onShowPickerView = nil
        onShowSettings = nil
    }
}
