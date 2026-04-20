//
//  Created by Vonage on 16/4/26.
//

import AVKit
import Foundation
import SwiftUI
import VERAArchiving
import VERAAudioEffects
import VERABackgroundEffects
import VERACaptions
import VERACommonUI
import VERADomain
import VERAMeetingRoom
import VERAReactions
import VERASettings

/// The result of building a meeting room with ``MeetingRoomBuilder``.
///
/// Contains the fully composed SwiftUI view and the underlying view model
/// for external state observation (e.g., monitoring call state).
public struct MeetingRoomPrebuilt {

    /// The fully composed meeting room view with all feature overlays applied.
    ///
    /// Present this view directly (e.g., in a `.fullScreenCover`) for a
    /// complete meeting room experience.
    public let view: AnyView

    /// The meeting room view model for external state observation.
    ///
    /// Use this to monitor call state, archiving state, or other meeting room
    /// properties from the host app.
    public let viewModel: MeetingRoomViewModel
}

/// Builds a fully configured meeting room with a single fluent API call.
///
/// `MeetingRoomBuilder` encapsulates all the dependency wiring, plugin registration,
/// overlay composition, and bottom bar button assembly that was previously scattered
/// across `DependencyContainer`, `VERAApp`, and `NavigationCoordinator`.
///
/// ## Usage
/// ```swift
/// let result = MeetingRoomBuilder()
///     .baseURL(url)
///     .roomName("my-room")
///     .configuration(.init(allowMicrophoneControl: true, allowCameraControl: true))
///     .enabledFeatures([.chat, .captions, .reactions])
///     .onAction { action in
///         switch action {
///         case .navigateToGoodbye: coordinator.leaveMeeting()
///         case .navigateToWaitingRoom(let room): coordinator.goToWaitingRoom(room)
///         case .presentAlert(let alert): coordinator.showAlert(alert)
///         case .navigateToSettings: coordinator.goToSettings()
///         }
///     }
///     .build()
///
/// // Present the view
/// result.view
/// ```
///
/// ## Feature Configuration
/// Features are enabled at runtime via ``enabledFeatures(_:)`` instead of
/// compile-time `#if` flags. Only enabled features create dependencies and UI.
///
/// ## Dependency Injection
/// For advanced use cases, inject a shared `PublisherRepository` via
/// ``publisherRepository(_:)`` to reuse the publisher from a waiting room.
public final class MeetingRoomBuilder {

    private var baseURL: URL
    private var roomName: String
    private var _configuration = MeetingRoomConfiguration()
    private var _enabledFeatures: Set<MeetingRoomFeature> = []
    private var _onAction: ((MeetingRoomSDKAction) -> Void)?
    private var _publisherRepository: (any PublisherRepository)?
    private var _initialBackgroundBlurLevel: BlurLevel?
    private var _initialNoiseSuppressionState: NoiseSuppressionState?
    private var _appGroupIdentifier: String?
    private var _broadcastExtensionBundleId: String?

    /// Creates a new meeting room builder.
    public init(
        baseURL: URL,
        roomName: String
    ) {
        self.baseURL = baseURL
        self.roomName = roomName
    }

    // MARK: - Test-Visible Accessors

    /// The currently configured base URL. Visible for testing.
    var currentBaseURL: URL? { baseURL }

    /// The currently configured room name. Visible for testing.
    var currentRoomName: String? { roomName }

    /// The currently configured meeting room configuration. Visible for testing.
    var currentConfiguration: MeetingRoomConfiguration { _configuration }

    /// The currently configured enabled features. Visible for testing.
    var currentEnabledFeatures: Set<MeetingRoomFeature> { _enabledFeatures }

    /// The currently configured app group identifier. Visible for testing.
    var currentAppGroupIdentifier: String? { _appGroupIdentifier }

    /// The currently configured broadcast extension bundle ID. Visible for testing.
    var currentBroadcastExtensionBundleId: String? { _broadcastExtensionBundleId }

    /// Sets the base URL for API requests (room credentials, archiving, captions).
    ///
    /// - Parameter url: The backend API base URL.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func baseURL(_ url: URL) -> MeetingRoomBuilder {
        baseURL = url
        return self
    }

    /// Sets the room name to join.
    ///
    /// - Parameter name: The meeting room name.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func roomName(_ name: String) -> MeetingRoomBuilder {
        roomName = name
        return self
    }

    /// Sets the meeting room UI configuration.
    ///
    /// - Parameter config: Controls for microphone, camera, and participant list visibility.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func configuration(_ config: MeetingRoomConfiguration) -> MeetingRoomBuilder {
        _configuration = config
        return self
    }

    /// Sets which features are enabled in the meeting room.
    ///
    /// Only enabled features will create dependencies, register plugins,
    /// and render UI elements.
    ///
    /// - Parameter features: The set of features to enable.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func enabledFeatures(_ features: Set<MeetingRoomFeature>) -> MeetingRoomBuilder {
        _enabledFeatures = features
        return self
    }

    /// Sets the action handler for navigation and alert callbacks.
    ///
    /// The host app must handle these actions to integrate navigation
    /// (goodbye screen, waiting room, settings) and alert presentation.
    ///
    /// - Parameter handler: Closure called when the meeting room emits an action.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func onAction(_ handler: @escaping (MeetingRoomSDKAction) -> Void) -> MeetingRoomBuilder {
        _onAction = handler
        return self
    }

    /// Injects an external publisher repository for publisher reuse.
    ///
    /// Use this to share the publisher created in the waiting room with
    /// the meeting room, preserving camera/microphone state.
    ///
    /// - Parameter repository: The shared publisher repository.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func publisherRepository(_ repository: any PublisherRepository) -> MeetingRoomBuilder {
        _publisherRepository = repository
        return self
    }

    /// Sets the initial background blur level from the waiting room.
    ///
    /// When the user configured background blur in the waiting room,
    /// pass the blur level here to maintain it in the meeting room.
    ///
    /// - Parameter level: The blur level to apply initially.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func initialBackgroundBlurLevel(_ level: BlurLevel) -> MeetingRoomBuilder {
        _initialBackgroundBlurLevel = level
        return self
    }

    /// Sets the initial noise suppression state from the waiting room.
    ///
    /// - Parameter state: The noise suppression state to apply initially.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func initialNoiseSuppressionState(_ state: NoiseSuppressionState) -> MeetingRoomBuilder {
        _initialNoiseSuppressionState = state
        return self
    }

    /// Sets the app group identifier for screen share credential storage.
    ///
    /// Required when screen share is enabled to allow the broadcast extension
    /// to access shared credentials.
    ///
    /// - Parameter identifier: The app group identifier (e.g., "group.com.vonage.VERA").
    /// - Returns: The builder for chaining.
    @discardableResult
    public func appGroupIdentifier(_ identifier: String) -> MeetingRoomBuilder {
        _appGroupIdentifier = identifier
        return self
    }

    /// Sets the bundle identifier of the broadcast extension for screen sharing.
    ///
    /// - Parameter bundleId: The broadcast extension bundle ID.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func broadcastExtensionBundleId(_ bundleId: String) -> MeetingRoomBuilder {
        _broadcastExtensionBundleId = bundleId
        return self
    }

    /// Builds the meeting room with all configured features and dependencies.
    ///
    /// This method creates the complete dependency graph, registers plugins,
    /// assembles bottom bar buttons, and composes the view with all overlays.
    ///
    /// - Precondition: `baseURL` and `roomName` must be set.
    /// - Returns: A ``MeetingRoomPrebuilt`` containing the composed view and view model.
    @MainActor
    public func build() -> MeetingRoomPrebuilt {
        let onAction = _onAction ?? { _ in }

        // 1. Create container with all dependencies
        let container = MeetingRoomSDKContainer(
            baseURL: baseURL,
            enabledFeatures: _enabledFeatures,
            configuration: _configuration,
            publisherRepository: _publisherRepository,
            appGroupIdentifier: _appGroupIdentifier,
            broadcastExtensionBundleId: _broadcastExtensionBundleId
        )

        // 2. Create buttons assembler
        let buttonsAssembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: _enabledFeatures
        )

        // 3. Set up feature view models that need pre-creation

        // Background Effects
        if _enabledFeatures.contains(.backgroundEffects) {
            let (_, blurVM) = container.backgroundBlurFactory.makeBlurButton(
                getCurrentPublisher: container.publisherRepository.getPublisher
            )
            if let initialLevel = _initialBackgroundBlurLevel {
                blurVM.currentBlurLevel = initialLevel
            }
            buttonsAssembler.backgroundBlurButtonViewModel = blurVM
        }

        // Archiving
        if _enabledFeatures.contains(.archiving) {
            let (_, archiveVM) = container.archivingFactory.makeArchivingButton(
                roomName: roomName,
                showAlert: { alertItem in
                    onAction(.presentAlert(alertItem))
                }
            )
            archiveVM.setup()
            buttonsAssembler.archiveButtonViewModel = archiveVM
        }

        // Captions
        var captionsButtonViewModel: CaptionsButtonViewModel?
        var captionsViewModel: CaptionsViewModel?
        if _enabledFeatures.contains(.captions) {
            let (_, captionsBtnVM) = container.captionsFactory.makeCaptionsButton(roomName: roomName)
            captionsBtnVM.setup()
            captionsButtonViewModel = captionsBtnVM
            buttonsAssembler.captionsButtonViewModel = captionsBtnVM

            let (_, captionsVM) = container.captionsFactory.makeCaptionsView()
            captionsViewModel = captionsVM
        }

        // Reactions
        var emojiButtonContainerViewModel: EmojiButtonContainerViewModel?
        var emojiPickerContainerViewModel: EmojiPickerContainerViewModel?
        var floatingEmojisOverlayViewModel: FloatingEmojisOverlayViewModel?
        if _enabledFeatures.contains(.reactions) {
            emojiButtonContainerViewModel = container.reactionsFactory.makeEmojiButton().viewModel
            buttonsAssembler.emojiButtonContainerViewModel = emojiButtonContainerViewModel

            floatingEmojisOverlayViewModel = container.reactionsFactory.makeFloatingEmojisOverlay().viewModel
            emojiPickerContainerViewModel = container.reactionsFactory.makeEmojiPickerContainer().viewModel
        }

        // Settings (stats overlay)
        var statsOverlayViewModel: StatsOverlayViewModel?
        if _enabledFeatures.contains(.settings) {
            statsOverlayViewModel = container.settingsFactory.makeStatsOverlayViewModel()
        }

        // Audio Effects
        if _enabledFeatures.contains(.audioEffects) {
            let audioVM = container.audioEffectsFactory.makeMeetingNoiseSuppressionButton().viewModel
            if let initialState = _initialNoiseSuppressionState {
                audioVM.state = initialState
            }
            buttonsAssembler.meetingNoiseSuppressionButtonViewModel = audioVM
        }

        // 4. Create the meeting room view + view model via factory
        let (_, meetingRoomViewModel) = container.meetingRoomFactory.make(
            roomName: roomName,
            getExternalButtons: { state in
                buttonsAssembler.buildButtons(state)
            },
            onActionHandler: { action in
                switch action {
                case .presentAlert(let alertItem):
                    onAction(.presentAlert(alertItem))
                case .navigateToGoodbye:
                    onAction(.navigateToGoodbye)
                case .navigateToSettings:
                    onAction(.navigateToSettings)
                case .navigateToWaitingRoom(let room):
                    onAction(.navigateToWaitingRoom(room))
                default:
                    break
                }
            }
        )

        // 5. Set top trailing buttons (audio route picker)
        meetingRoomViewModel.extraTopTrailingButtons = Self.topTrailingButtons

        // 6. Compose the final view with all overlays
        let composedView = MeetingRoomComposedView(
            meetingRoomFactory: container.meetingRoomFactory,
            viewModel: meetingRoomViewModel,
            container: container,
            enabledFeatures: _enabledFeatures,
            buttonsAssembler: buttonsAssembler,
            onAction: onAction,
            captionsButtonViewModel: captionsButtonViewModel,
            captionsViewModel: captionsViewModel,
            floatingEmojisOverlayViewModel: floatingEmojisOverlayViewModel,
            emojiPickerContainerViewModel: emojiPickerContainerViewModel,
            statsOverlayViewModel: statsOverlayViewModel
        )

        return MeetingRoomPrebuilt(
            view: AnyView(composedView),
            viewModel: meetingRoomViewModel
        )
    }

    // MARK: - Top Trailing Buttons

    private static var topTrailingButtons: [ViewGenerator] {
        [
            .init(
                id: "Speaker",
                content: {
                    ZStack {
                        AudioRoutePickerView()
                            .frame(width: 44, height: 44)
                    }
                })
        ]
    }
}
