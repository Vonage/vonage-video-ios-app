//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation

/// A snapshot of the current call participants and active speaker.
///
/// Contains the local participant (if any), the list of remote participants,
/// and the identifier of the current active speaker if one is detected.
public struct ParticipantsState: Equatable {
    /// The local participant if one is currently publishing media; otherwise `nil`.
    public let localParticipant: Participant?
    /// The list of remote participants currently in the session.
    public let participants: [Participant]
    /// The identifier of the participant currently detected as active speaker, if any.
    public let activeParticipantId: String?

    /// An empty state with no local or remote participants and no active speaker.
    public static var empty: ParticipantsState {
        ParticipantsState(
            localParticipant: nil,
            participants: [],
            activeParticipantId: nil)
    }

    /// Creates a new participants state value.
    ///
    /// - Parameters:
    ///   - localParticipant: The local participant if present.
    ///   - participants: The current list of remote participants.
    ///   - activeParticipantId: The identifier of the current active speaker, if any.
    public init(
        localParticipant: Participant?,
        participants: [Participant],
        activeParticipantId: String?
    ) {
        self.localParticipant = localParticipant
        self.participants = participants
        self.activeParticipantId = activeParticipantId
    }
}

/// The high-level connection state of a call.
///
/// Represents lifecycle stages of a call from idle to disconnected.
/// Use it to drive connection-related UI and guard call operations.
public enum CallState {
    /// Initial state, no connection established.
    case idle
    /// The call is connected and active.
    case connected
    /// A connection attempt is in progress.
    case connecting
    /// A disconnect operation is in progress.
    case disconnecting
    /// The call has been disconnected and cleaned up.
    case disconnected
}

/// The high-level state of a recording call
///
/// Represents if the current call is being recording or not.
/// Use it to drive recording related UI display.
public enum ArchivingState: Equatable {
    case idle
    case archiving(ArchiveID)
}

public typealias ArchiveID = String

/// The high-level state of the captions feature.
///
/// Represents whether the current call has captions enabled or not.
/// Use it to drive captions-related UI display.
public enum CaptionsState: Equatable {
    case enabled(CaptionsID)
    case disabled
}

extension CaptionsState {
    public var captionsEnabled: Bool {
        if case .enabled = self {
            return true
        }
        return false
    }
}

public typealias CaptionsID = String

/// The high-level state of the Noise Suppression feature.
///
/// Represents whether the current call has noise suppression enabled or not.
/// Use it to drive noise suppression-related UI display.
public enum NoiseSuppressionState: Equatable {
    case enabled
    case disabled
    case idle
}

extension NoiseSuppressionState {
    public var isEnabled: Bool {
        return self == .enabled
    }
}

/// Provides a publisher that emits participant state updates.
///
/// Implementers emit ``ParticipantsState`` values as the call’s participant set
/// changes (joins, leaves, media toggles, active speaker updates).
public protocol ParticipantsPublisherProvider: AnyObject {
    /// A publisher that emits ``ParticipantsState`` updates, never fails.
    var participantsPublisher: AnyPublisher<ParticipantsState, Never> { get }
}

/// Provides a publisher that emits session-level events and errors.
///
/// Use this publisher to react to errors and notable session events (e.g., signals).
public protocol EventsPublisherProvider: AnyObject {
    /// A publisher that emits ``SessionEvent`` values, never fails.
    var eventsPublisher: AnyPublisher<SessionEvent, Never> { get }
}

/// Provides a publisher for local media publishing state.
///
/// Emits changes to audio/video publishing toggles suitable for UI binding.
public protocol SessionStatePublisherProvider: AnyObject {
    /// A publisher that emits ``SessionState`` values, never fails.
    var statePublisher: AnyPublisher<SessionState, Never> { get }
}

/// Provides a publisher for the call connection state.
///
/// Use to drive connection-related UI and guard operations that require a particular state.
public protocol CallStatePublisherProvider: AnyObject {
    /// A publisher that emits ``CallState`` values, never fails.
    var callState: AnyPublisher<CallState, Never> { get }
}

/// Provides a publisher for the call archiving state.
///
/// Use to drive recording-related UI operations.
public protocol CallArchivingPublisherProvider: AnyObject {
    /// A publisher that emits ``ArchivingState`` values, never fails.
    var archivingState: AnyPublisher<ArchivingState, Never> { get }
}

/// Defines the primary connection lifecycle operations for a call.
///
/// Conformers manage establishing and tearing down the underlying session connection.
public protocol CallConnectable: AnyObject {
    /// Initiates a connection to the session.
    ///
    /// - Important: Implementations should transition to ``CallState/connecting`` and, on success, ``CallState/connected``.
    func connect()

    /// Disconnects from the session and performs cleanup.
    ///
    /// - Throws: An error if the call is not in a state that allows disconnection,
    ///   or if the disconnect operation fails.
    /// - Important: Implementations should transition to ``CallState/disconnecting`` and then ``CallState/disconnected``.
    func disconnect() async throws
}

/// Controls local media publishing and mute state.
///
/// Conformers should reflect changes via their ``SessionStatePublisherProvider/statePublisher``.
public protocol MediaToggleable: AnyObject {
    /// Returns `true` when both local audio and video are disabled.
    var isMuted: Bool { get }

    /// Toggles local video publishing on/off.
    func toggleLocalVideo()
    /// Switches the local camera between front and back.
    func toggleLocalCamera()
    /// Toggles local audio publishing on/off.
    func toggleLocalAudio()

    /// Mutes or unmutes both local audio and video simultaneously.
    ///
    /// - Parameter isMuted: When `true`, disables both audio and video; when `false`, enables both.
    func muteLocalMedia(_ isMuted: Bool)
}

/// Controls the call's hold state.
///
/// When a call is on hold, implementations typically disable local publishing and remote subscriptions
/// while keeping the session connection active.
public protocol HoldeableCall: AnyObject {
    /// Returns `true` when the call is currently on hold.
    var isOnHold: Bool { get }

    /// Sets the hold state of the call.
    ///
    /// - Parameter isOnHold: `true` to put the call on hold; `false` to resume normal operation.
    func setOnHold(_ isOnHold: Bool)
}

/// Controls the captions state
///
/// Execute enableCaptions to activate captions or disableCaptions to stop receiving caption updates
public protocol CaptionsProvider: AnyObject {
    /// Returns `true` when the captions are active
    var areCaptionsEnabled: Bool { get }

    /// A publisher that emits ``[CaptionItem]`` values, never fails.
    var captionsPublisher: AnyPublisher<[CaptionItem], Never> { get }

    /// Activates the captions
    func enableCaptions() async

    /// Deactivates the captions
    func disableCaptions() async
}

/// Allows applying new publisher settings (resolution, codec, etc.) to an active call.
///
/// Vonage SDK settings like resolution, frame rate, and codec are baked into
/// the ``OTPublisher`` at creation time. Applying new settings at runtime
/// requires a **republish cycle**: unpublish → recreate publisher → re-publish.
///
/// The implementation preserves runtime state (audio/video mute, camera position,
/// video transformers, stats delegates) across the republish.
///
/// - SeeAlso: ``PublisherSettings``, ``CallFacade``
public protocol PublisherSettingsApplicable: AnyObject {
    /// Applies new publisher settings to the active call.
    ///
    /// Only SDK-level fields (resolution, frame rate, codec, audio bitrate,
    /// audio fallback) from `settings` are used. Runtime state such as
    /// audio/video publishing, camera position and video transformers
    /// are preserved automatically.
    ///
    /// - Parameter settings: The desired publisher configuration.
    /// - Throws: If the unpublish, recreate, or re-publish step fails.
    func applyPublisherAdvancedSettings(_ settings: PublisherAdvancedSettings) async throws
}

/// A unified façade protocol for managing a video call.
///
/// Conformers expose reactive state via publishers, connection lifecycle operations,
/// media controls, and hold management in a single cohesive interface.
///
/// ## Composition
/// Conforms to:
/// - ``ParticipantsPublisherProvider``
/// - ``EventsPublisherProvider``
/// - ``SessionStatePublisherProvider``
/// - ``CallConnectable``
/// - ``MediaToggleable``
/// - ``CallStatePublisherProvider``
/// - ``HoldeableCall``
public protocol CallFacade: AnyObject,
    ParticipantsPublisherProvider,
    EventsPublisherProvider,
    SessionStatePublisherProvider,
    CallConnectable,
    MediaToggleable,
    CallStatePublisherProvider,
    HoldeableCall,
    CallArchivingPublisherProvider,
    CaptionsProvider,
    NetworkStatsProvider,
    PublisherSettingsApplicable
{}

/// Errors that can occur during call operations.
///
/// - SeeAlso: ``callState``, ``disconnect()``
public enum CallError: Swift.Error {
    /// An attempt was made to disconnect a call that is not in the connected state.
    ///
    /// Ensure ``callState`` is ``CallState/connected`` before calling ``disconnect()``.
    case callNotConnected
}
