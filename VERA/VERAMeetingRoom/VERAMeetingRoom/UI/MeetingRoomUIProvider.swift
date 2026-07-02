//
//  Created by Vonage on 29/6/26.
//

import Combine
import SwiftUI

/// A request for the meeting room to present SDK-managed UI on behalf of custom controls.
public struct MeetingRoomPresentationRequest: Identifiable {
    /// Presentation styles supported by the meeting room.
    public enum Style: Equatable {
        /// Present the request as a system dialog.
        case dialog

        /// Present the request as an overlay above the meeting room.
        case overlay

        /// Present the request as a sheet.
        case sheet
    }

    /// Stable identifier for this presentation request.
    public let id: String

    /// Presentation style requested by the control.
    public let style: Style

    /// User-facing title for the presentation.
    public let title: String

    /// Optional user-facing message for default dialog, overlay, or sheet content.
    public let message: String?

    /// Optional custom SwiftUI content used by sheet and overlay presentations.
    public let content: AnyView?

    /// Optional identifier of the button or control that created this request.
    ///
    /// Hosts can use this to reconcile active state when the presentation is dismissed.
    public let sourceButtonId: String?

    /// Closure called when the SDK dismisses the presentation.
    public let onDismiss: (@MainActor () -> Void)?

    /// Creates a presentation request with custom SwiftUI content.
    ///
    /// - Parameters:
    ///   - id: Stable request identifier. Defaults to a generated UUID string.
    ///   - style: Requested presentation style.
    ///   - title: User-facing title.
    ///   - message: Optional user-facing message.
    ///   - sourceButtonId: Optional identifier of the source button or control.
    ///   - onDismiss: Closure called when the SDK dismisses the presentation.
    ///   - content: Custom SwiftUI content for the presentation.
    public init(
        id: String = UUID().uuidString,
        style: Style,
        title: String,
        message: String? = nil,
        sourceButtonId: String? = nil,
        onDismiss: (@MainActor () -> Void)? = nil,
        content: AnyView? = nil
    ) {
        self.id = id
        self.style = style
        self.title = title
        self.message = message
        self.content = content
        self.sourceButtonId = sourceButtonId
        self.onDismiss = onDismiss
    }
}

/// A presenter exposed to custom bottom bars and extra buttons.
public struct MeetingRoomPresentationHandler {
    /// Presents the supplied request using the meeting room presentation container.
    public let present: @MainActor (MeetingRoomPresentationRequest) -> Void

    /// Dismisses an active presentation by request identifier.
    public let dismiss: @MainActor (String) -> Void

    /// Creates a presentation handler.
    ///
    /// Both closures default to no-ops so contexts can be built in tests and previews.
    public init(
        present: @escaping @MainActor (MeetingRoomPresentationRequest) -> Void = { _ in },
        dismiss: @escaping @MainActor (String) -> Void = { _ in }
    ) {
        self.present = present
        self.dismiss = dismiss
    }
}

/// A reusable SDK control for custom bottom bar implementations.
public struct MeetingRoomBottomBarControl: Identifiable {
    /// Stable identifier for the control.
    public let id: String

    /// User-facing label for the control.
    public let label: String

    /// Icon that represents the control.
    public let image: Image

    /// Whether the control should be rendered as active.
    public let isActive: Bool

    /// Optional accessibility identifier for UI automation.
    public let accessibilityIdentifier: String?

    /// Action executed when the host UI activates the control.
    public let action: @MainActor () -> Void

    /// Creates a reusable bottom bar control.
    ///
    /// - Parameters:
    ///   - id: Stable identifier for the control.
    ///   - label: User-facing label.
    ///   - image: Icon that represents the control.
    ///   - isActive: Whether the control should be rendered as active.
    ///   - accessibilityIdentifier: Optional identifier for UI automation.
    ///   - action: Action executed when the control is activated.
    public init(
        id: String,
        label: String,
        image: Image,
        isActive: Bool = false,
        accessibilityIdentifier: String? = nil,
        action: @escaping @MainActor () -> Void
    ) {
        self.id = id
        self.label = label
        self.image = image
        self.isActive = isActive
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }
}

/// SDK controls available to a custom bottom bar.
public struct MeetingRoomBottomBarControls {
    /// Microphone toggle control.
    public let microphone: MeetingRoomBottomBarControl

    /// Camera toggle control.
    public let camera: MeetingRoomBottomBarControl

    /// Optional SDK participant list toggle control.
    ///
    /// Hosts can ignore this control and build their own participant UI from
    /// `MeetingRoomBottomBarContext.state.participants`.
    public let participants: MeetingRoomBottomBarControl?

    /// Layout toggle control.
    public let layout: MeetingRoomBottomBarControl

    /// End-call control.
    public let endCall: MeetingRoomBottomBarControl

    /// Creates the set of SDK controls available to a custom bottom bar.
    public init(
        microphone: MeetingRoomBottomBarControl,
        camera: MeetingRoomBottomBarControl,
        participants: MeetingRoomBottomBarControl?,
        layout: MeetingRoomBottomBarControl,
        endCall: MeetingRoomBottomBarControl
    ) {
        self.microphone = microphone
        self.camera = camera
        self.participants = participants
        self.layout = layout
        self.endCall = endCall
    }
}

/// Context passed to a host-provided custom bottom bar.
public struct MeetingRoomBottomBarContext {
    /// Current meeting room state.
    public let state: MeetingRoomState

    /// Backward-compatible action closures exposed by the meeting room.
    public let actions: MeetingRoomActions

    /// Combined SDK and host extra buttons.
    ///
    /// This remains available for hosts that want to reuse extra buttons, but a
    /// fully custom bottom bar can ignore it and build directly from `controls`.
    public let buttons: [BottomBarButton]

    /// Recommended SDK controls for recreating the built-in bottom bar behavior.
    public let controls: MeetingRoomBottomBarControls

    /// SDK-managed presenter for dialog, overlay, and sheet requests.
    public let presentationHandler: MeetingRoomPresentationHandler

    /// Creates a custom bottom bar context.
    ///
    /// - Parameters:
    ///   - state: Current meeting room state.
    ///   - actions: Backward-compatible action closures.
    ///   - buttons: Combined SDK and host extra buttons.
    ///   - controls: SDK controls for custom bottom bars.
    ///   - presentationHandler: SDK-managed presentation handler.
    public init(
        state: MeetingRoomState,
        actions: MeetingRoomActions,
        buttons: [BottomBarButton],
        controls: MeetingRoomBottomBarControls,
        presentationHandler: MeetingRoomPresentationHandler = .init()
    ) {
        self.state = state
        self.actions = actions
        self.buttons = buttons
        self.controls = controls
        self.presentationHandler = presentationHandler
    }
}

/// Provides host-driven UI customization for the meeting room.
///
/// `bottomBarButtons()` adds host-provided buttons to the SDK bottom bar.
/// `bottomBarContent(context:)` can replace the full bottom bar when the host
/// wants to render it.
public protocol MeetingRoomUIProvider {
    /// Publishes whenever provider-driven UI should be refreshed.
    var updates: AnyPublisher<Void, Never> { get }

    /// Returns host-provided buttons appended to the SDK bottom bar.
    @MainActor
    func bottomBarButtons() -> [BottomBarButton]

    /// Returns a full custom bottom bar, or `nil` to use the SDK bottom bar.
    ///
    /// When this returns a view, the host owns the visual bottom bar and can use
    /// `context.controls`, `context.state`, and `context.presentationHandler`.
    @MainActor
    func bottomBarContent(context: MeetingRoomBottomBarContext) -> AnyView?
}

extension MeetingRoomUIProvider {
    /// Default implementation that keeps the SDK bottom bar.
    @MainActor
    public func bottomBarContent(context: MeetingRoomBottomBarContext) -> AnyView? {
        nil
    }
}

/// Default meeting room UI provider used when the host does not customize UI.
public struct DefaultMeetingRoomUIProvider: MeetingRoomUIProvider {
    private let makeBottomBarButtons: @MainActor () -> [BottomBarButton]
    private let makeBottomBarContent: @MainActor (MeetingRoomBottomBarContext) -> AnyView?

    /// Publishes whenever this provider's bottom bar buttons or content should refresh.
    public let updates: AnyPublisher<Void, Never>

    /// Creates an empty provider that does not customize the meeting room UI.
    public init() {
        self.init {
            []
        }
    }

    /// Creates a configurable provider backed by closures.
    ///
    /// - Parameters:
    ///   - bottomBarButtons: Closure returning buttons appended to the SDK bottom bar.
    ///   - updates: Publisher that emits when provider-driven UI should refresh.
    ///   - bottomBarContent: Closure returning a custom bottom bar, or `nil` for the SDK bottom bar.
    public init(
        bottomBarButtons: @escaping @MainActor () -> [BottomBarButton],
        updates: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher(),
        bottomBarContent: @escaping @MainActor (MeetingRoomBottomBarContext) -> AnyView? = { _ in nil }
    ) {
        self.makeBottomBarButtons = bottomBarButtons
        self.makeBottomBarContent = bottomBarContent
        self.updates = updates
    }

    /// Returns the configured host-provided bottom bar buttons.
    @MainActor
    public func bottomBarButtons() -> [BottomBarButton] {
        makeBottomBarButtons()
    }

    /// Returns the configured custom bottom bar content, or `nil` to keep the SDK bottom bar.
    @MainActor
    public func bottomBarContent(context: MeetingRoomBottomBarContext) -> AnyView? {
        makeBottomBarContent(context)
    }
}
