//
//  Created by Vonage on 16/4/26.
//

import Combine
import Foundation
import VERAArchiving
import VERAAudioEffects
import VERABackgroundEffects
import VERACaptions
import VERAChat
import VERACommonUI
import VERADomain
import VERAMeetingRoom
import VERAReactions

/// Assembles bottom bar buttons based on runtime feature configuration.
///
/// Replaces the scattered `#if FEATURE_ENABLED` compilation conditions
/// previously used in `DependencyContainer+BottomBarButtons` and `VERAApp.getBottomBarButtons()`.
@MainActor
final class BottomBarButtonsAssembler {

    private let container: MeetingRoomSDKContainer
    private let enabledFeatures: Set<MeetingRoomFeature>
    private let buttonsDidChangeSubject = PassthroughSubject<Void, Never>()
    private var noiseSuppressionCancellable: AnyCancellable?
    private var isChatPresented = false
    private var isReactionsPickerPresented = false
    private var isSettingsPresented = false
    private var isEffectsPresented = false
    private var isFeedbackFormPresented = false

    // Feature view models created during meeting room setup
    var videoEffectsViewModel: VideoEffectsViewModel?
    var archiveButtonViewModel: ArchiveButtonViewModel?
    var captionsButtonViewModel: CaptionsButtonViewModel?
    var emojiButtonContainerViewModel: EmojiButtonContainerViewModel?
    var meetingNoiseSuppressionButtonViewModel: MeetingNoiseSuppressionViewModel? {
        didSet {
            let didChange: Bool
            switch (oldValue, meetingNoiseSuppressionButtonViewModel) {
            case (let oldValue?, let newValue?):
                didChange = oldValue !== newValue
            case (nil, nil):
                didChange = false
            default:
                didChange = true
            }
            guard didChange else { return }

            bindNoiseSuppressionUpdates(meetingNoiseSuppressionButtonViewModel)
        }
    }

    // Bindings for sheet/overlay presentation
    var onShowChat: (() -> Void)?
    var onShowReactions: (() -> Void)?
    var onShowSettings: (() -> Void)?
    var onShowFeedbackForm: (() -> Void)?
    var onShowEffects: (() -> Void)?

    var buttonsDidChange: AnyPublisher<Void, Never> {
        let archiveUpdates =
            archiveButtonViewModel?.$state
            .dropFirst()
            .map { _ in () }
            .eraseToAnyPublisher()
            ?? Empty().eraseToAnyPublisher()

        let effectsUpdates =
            videoEffectsViewModel?.$selectedEffect
            .dropFirst()
            .map { _ in () }
            .eraseToAnyPublisher()
            ?? Empty().eraseToAnyPublisher()

        let captionsUpdates =
            captionsButtonViewModel?.$state
            .dropFirst()
            .map { _ in () }
            .eraseToAnyPublisher()
            ?? Empty().eraseToAnyPublisher()

        let chatUpdates =
            enabledFeatures.contains(.chat)
            ? container.chatBadgeButtonViewModel.$unreadMessagesCount
                .dropFirst()
                .map { _ in () }
                .eraseToAnyPublisher()
            : Empty().eraseToAnyPublisher()

        return Publishers.MergeMany([
            archiveUpdates,
            effectsUpdates,
            captionsUpdates,
            chatUpdates,
            buttonsDidChangeSubject.eraseToAnyPublisher(),
        ])
        .eraseToAnyPublisher()
    }

    init(
        container: MeetingRoomSDKContainer,
        enabledFeatures: Set<MeetingRoomFeature>
    ) {
        self.container = container
        self.enabledFeatures = enabledFeatures
    }

    /// Builds the array of extra bottom bar buttons based on enabled features.
    ///
    /// Called by the meeting room UI provider each time the meeting room needs
    /// the current feature buttons.
    ///
    /// - Returns: Array of feature buttons to display in the bottom bar.
    func buildButtons() -> [BottomBarButton] {
        var buttons: [BottomBarButton] = []

        if enabledFeatures.contains(.chat) {
            buttons.append(makeChatButton())
        }

        if enabledFeatures.contains(.backgroundEffects), let viewModel = videoEffectsViewModel {
            buttons.append(makeBackgroundEffectsButton(viewModel))
        }

        if enabledFeatures.contains(.archiving), let viewModel = archiveButtonViewModel {
            buttons.append(makeArchiveButton(viewModel))
        }

        if enabledFeatures.contains(.captions), let viewModel = captionsButtonViewModel {
            buttons.append(makeCaptionsButton(viewModel))
        }

        if enabledFeatures.contains(.reactions), let viewModel = emojiButtonContainerViewModel {
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

        if enabledFeatures.contains(.feedback) {
            buttons.append(makeFeedbackReportButton())
        }

        return buttons
    }

    // MARK: - Individual Button Builders

    private func makeChatButton() -> BottomBarButton {
        let viewModel = container.chatBadgeButtonViewModel
        return .init(
            viewModel,
            isActive: isChatPresented,
            overflowSelectionBehavior: .dismissBeforeAction
        ) { [weak self] in
            viewModel.chatDidOpen()
            self?.onShowChat?()
        }
    }

    private func makeBackgroundEffectsButton(
        _ viewModel: VideoEffectsViewModel
    ) -> BottomBarButton {
        .init(
            viewModel,
            isActive: isEffectsPresented || viewModel.isActive,
            overflowSelectionBehavior: .dismissBeforeAction
        ) { [weak self] in
            self?.onShowEffects?()
        }
    }

    private func makeFeedbackReportButton() -> BottomBarButton {
        let item = FeedbackBottomItemPresenter { [weak self] in
            self?.onShowFeedbackForm?()
        }
        return .init(item, isActive: isFeedbackFormPresented)
    }

    private func makeArchiveButton(
        _ viewModel: ArchiveButtonViewModel
    ) -> BottomBarButton {
        .init(viewModel, overflowSelectionBehavior: .dismissBeforeAction)
    }

    private func makeCaptionsButton(
        _ viewModel: CaptionsButtonViewModel
    ) -> BottomBarButton {
        .init(viewModel)
    }

    private func makeReactionsButton(
        _ viewModel: EmojiButtonContainerViewModel
    ) -> BottomBarButton {
        let item = ReactionsBottomItemPresenter(
            isPickerPresented: isReactionsPickerPresented,
            viewModel: viewModel
        ) { [weak self] in
            self?.onShowReactions?()
        }
        return .init(item)
    }

    private func makeScreenShareButton() -> BottomBarButton {
        let extensionId =
            container.broadcastExtensionBundleId
            ?? (Bundle.main.bundleIdentifier ?? "com.vonage.VERA") + ".BroadcastExtension"
        let item = ScreenShareBottomItemPresenter(extensionId: extensionId)
        return .init(item)
    }

    private func makeSettingsButton() -> BottomBarButton {
        let item = SettingsBottomItemPresenter { [weak self] in
            self?.onShowSettings?()
        }
        return .init(item, isActive: isSettingsPresented)
    }

    private func makeAudioEffectsButton() -> BottomBarButton {
        let viewModel: MeetingNoiseSuppressionViewModel
        if let existing = meetingNoiseSuppressionButtonViewModel {
            viewModel = existing
        } else {
            viewModel = container.audioEffectsFactory.makeMeetingNoiseSuppressionButton().viewModel
            meetingNoiseSuppressionButtonViewModel = viewModel
        }
        return .init(viewModel)
    }

    /// Rebuilds buttons using the most recent state.
    ///
    /// Used when a feature view model's published properties change (e.g. selected video effect)
    /// and the bottom bar needs to reflect the updated icon.
    func rebuildButtons() -> [BottomBarButton] {
        buildButtons()
    }

    func setReactionsPickerPresented(_ isPresented: Bool) {
        guard isReactionsPickerPresented != isPresented else { return }

        isReactionsPickerPresented = isPresented
        buttonsDidChangeSubject.send()
    }

    func setChatPresented(_ isPresented: Bool) {
        guard isChatPresented != isPresented else { return }

        isChatPresented = isPresented
        buttonsDidChangeSubject.send()
    }

    func setSettingsPresented(_ isPresented: Bool) {
        guard isSettingsPresented != isPresented else { return }

        isSettingsPresented = isPresented
        buttonsDidChangeSubject.send()
    }

    func setEffectsPresented(_ isPresented: Bool) {
        guard isEffectsPresented != isPresented else { return }

        isEffectsPresented = isPresented
        buttonsDidChangeSubject.send()
    }

    func setFeedbackFormPresented(_ isPresented: Bool) {
        guard isFeedbackFormPresented != isPresented else { return }

        isFeedbackFormPresented = isPresented
        buttonsDidChangeSubject.send()
    }

    private func bindNoiseSuppressionUpdates(_ viewModel: MeetingNoiseSuppressionViewModel?) {
        noiseSuppressionCancellable = nil
        guard let viewModel else { return }

        noiseSuppressionCancellable = viewModel.$state
            .dropFirst()
            .sink { [weak self] _ in
                self?.buttonsDidChangeSubject.send()
            }
    }

    func cleanUp() {
        videoEffectsViewModel = nil
        archiveButtonViewModel = nil
        captionsButtonViewModel = nil
        emojiButtonContainerViewModel = nil
        meetingNoiseSuppressionButtonViewModel = nil

        onShowChat = nil
        onShowReactions = nil
        onShowSettings = nil
        onShowFeedbackForm = nil
        onShowEffects = nil
        noiseSuppressionCancellable = nil
        isChatPresented = false
        isReactionsPickerPresented = false
        isSettingsPresented = false
        isEffectsPresented = false
        isFeedbackFormPresented = false
    }
}
