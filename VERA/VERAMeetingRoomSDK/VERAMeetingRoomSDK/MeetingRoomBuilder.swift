//
//  Created by Vonage on 16/4/26.
//

import AVKit
import Foundation
import SwiftUI
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
/// let result = MeetingRoomBuilder(
///     baseURL: url,
///     roomName: "my-room"
/// )
///     .configuration(.init(allowMicrophoneControl: true, allowCameraControl: true))
///     .enabledFeatures([.chat, .captions, .reactions])
///     .onAction { action in
///         switch action {
///         case .callDidEnd: coordinator.leaveMeeting()
///         case .goBack(let room): coordinator.goToWaitingRoom(room)
///         }
///     }
///     .build()
///
/// // Present the view
/// result.view
/// ```
public final class MeetingRoomBuilder {

    var baseURL: URL
    var roomName: String
    var _configuration = MeetingRoomConfiguration()
    var _enabledFeatures: Set<MeetingRoomFeature> = []
    var _onAction: ((MeetingRoomSDKAction) -> Void)?
    var _publisherSettings: PublisherSettings = .init()
    var _appGroupIdentifier: String?
    var _broadcastExtensionBundleId: String?
    var _theme: MeetingRoomTheme?
    var _sessionKeyHolder: SessionKeyHolder?

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

    /// The currently configured publisher settings. Visible for testing.
    var currentPublisherSettings: PublisherSettings? { _publisherSettings }

    /// The currently configured theme. Visible for testing.
    var currentTheme: MeetingRoomTheme? { _theme }

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
    /// (callDidEnd, goBack) and alert presentation.
    ///
    /// - Parameter handler: Closure called when the meeting room emits an action.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func onAction(_ handler: @escaping (MeetingRoomSDKAction) -> Void) -> MeetingRoomBuilder {
        _onAction = handler
        return self
    }

    /// Sets the initial publisher configuration.
    ///
    /// The SDK creates its own publisher internally using these settings.
    /// Use this to carry over user preferences (username, resolution, codec,
    /// audio/video flags) from the waiting room without exposing the
    /// publisher repository.
    ///
    /// - Parameter settings: The publisher configuration to apply.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func publisherSettings(_ settings: PublisherSettings) -> MeetingRoomBuilder {
        _publisherSettings = settings
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

    /// Sets a custom theme for the meeting room UI.
    ///
    /// Use ``MeetingRoomTheme/vonage`` as a starting point and modify
    /// individual color properties to match your brand.
    ///
    /// ```swift
    /// var theme = MeetingRoomTheme.vonage
    /// theme.primary = .blue
    /// builder.theme(theme)
    /// ```
    ///
    /// - Parameter theme: The theme to apply.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func theme(_ theme: MeetingRoomTheme) -> MeetingRoomBuilder {
        _theme = theme
        return self
    }

    /// Sets an external session key holder for sharing the session key JWT.
    ///
    /// When provided, the builder uses this holder instead of creating its own.
    /// This allows the host app to access the session key for features like
    /// the archives screen on the goodbye page.
    ///
    /// - Parameter holder: The session key holder to use.
    /// - Returns: The builder for chaining.
    @discardableResult
    public func sessionKeyHolder(_ holder: SessionKeyHolder) -> MeetingRoomBuilder {
        _sessionKeyHolder = holder
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
            publisherSettings: _publisherSettings,
            appGroupIdentifier: _appGroupIdentifier,
            broadcastExtensionBundleId: _broadcastExtensionBundleId
        )

        // Use external session key holder if provided
        if let externalHolder = _sessionKeyHolder {
            container.sessionKeyHolder = externalHolder
        }

        // 2. Create buttons assembler
        let buttonsAssembler = BottomBarButtonsAssembler(
            container: container,
            enabledFeatures: _enabledFeatures
        )

        // 3. Create alert presenter bridge
        let alertPresenter = AlertPresenter()

        // 4. Set up feature view models that need pre-creation

        // Background Effects
        if _enabledFeatures.contains(.backgroundEffects) {
            let (_, blurVM) = container.backgroundBlurFactory.makeBlurButton(
                getCurrentPublisher: container.publisherRepository.getPublisher
            )
            if let initialLevel = _publisherSettings.backgroundBlurLevel {
                blurVM.update(blurLevel: initialLevel)
            }
            buttonsAssembler.backgroundBlurButtonViewModel = blurVM
        }

        // Archiving
        if _enabledFeatures.contains(.archiving) {
            let (_, archiveVM) = container.archivingFactory.makeArchivingButton(
                showAlert: { [weak alertPresenter] alertItem in
                    alertPresenter?.present(alertItem)
                }
            )
            archiveVM.setup()
            buttonsAssembler.archiveButtonViewModel = archiveVM
        }

        // Captions
        var captionsButtonViewModel: CaptionsButtonViewModel?
        var captionsViewModel: CaptionsViewModel?
        if _enabledFeatures.contains(.captions) {
            let (_, captionsBtnVM) = container.captionsFactory.makeCaptionsButton()
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
            if let initialState = _publisherSettings.noiseSuppressionState {
                audioVM.updateState(to: initialState)
            }
            buttonsAssembler.meetingNoiseSuppressionButtonViewModel = audioVM
        }

        // 4. Create the meeting room view + view model via factory
        let (_, meetingRoomViewModel) = container.meetingRoomFactory.make(
            roomName: roomName,
            getExternalButtons: { [weak buttonsAssembler] state in
                buttonsAssembler?.buildButtons(state) ?? []
            },

            onActionHandler: { [weak self, weak alertPresenter, weak buttonsAssembler] action in
                switch action {
                case .presentAlert(let alertItem):
                    alertPresenter?.present(alertItem)
                case .navigateToGoodbye:
                    onAction(.callDidEnd)
                    alertPresenter?.reset()
                    buttonsAssembler?.cleanUp()
                    self?._onAction = nil
                case .navigateToSettings:
                    self?.navigateToSettings()
                case .navigateToWaitingRoom(let room):
                    onAction(.goBack(room))
                    alertPresenter?.reset()
                    buttonsAssembler?.cleanUp()
                    self?._onAction = nil
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
            alertPresenter: alertPresenter,
            captionsButtonViewModel: captionsButtonViewModel,
            captionsViewModel: captionsViewModel,
            floatingEmojisOverlayViewModel: floatingEmojisOverlayViewModel,
            emojiPickerContainerViewModel: emojiPickerContainerViewModel,
            statsOverlayViewModel: statsOverlayViewModel
        )

        let themedView =
            composedView
            .environment(\.meetingRoomTheme, _theme ?? .vonage)

        return MeetingRoomPrebuilt(
            view: AnyView(themedView),
            viewModel: meetingRoomViewModel
        )
    }

    private func navigateToSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
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
