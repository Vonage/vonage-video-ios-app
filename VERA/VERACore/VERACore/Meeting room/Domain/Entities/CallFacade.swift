//
//  Created by Vonage on 28/7/25.
//

import Combine
import Foundation
import VERADomain

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
    HoldeableCall
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
