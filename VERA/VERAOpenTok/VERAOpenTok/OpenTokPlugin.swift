//
//  Created by Vonage on 13/10/25.
//

import Foundation
import VERACore

/// Handles incoming OpenTok signals.
///
/// Conformers implement custom logic for processing session signals (e.g., chat messages,
/// control commands). Use alongside a signal channel/emitter to route signals into your feature.
///
/// - SeeAlso: ``OpenTokSignalChannel``, ``OpenTokSignalEmitter``, ``OpenTokSignal``
public protocol OpenTokSignalHandler {
    /// Processes an incoming signal.
    ///
    /// - Parameter signal: The received ``OpenTokSignal`` containing type and optional payload.
    func handleSignal(_ signal: OpenTokSignal)
}

/// Emits custom OpenTok signals over an active session.
///
/// Conformers provide a method to send `OutgoingSignal` to peers. Typically implemented by
/// the session wrapper and injected into plugins or features that need to broadcast events.
///
/// - SeeAlso: ``OpenTokSignalEmitter``, ``OutgoingSignal``
public protocol OpenTokSignalChannel: AnyObject {
    /// Sends an outgoing signal to the session.
    ///
    /// - Parameter signal: The ``OutgoingSignal`` to emit.
    /// - Throws: An error if the underlying SDK fails to send the signal.
    func emitSignal(_ signal: OutgoingSignal) throws
}

/// Holds a reference to a signal channel for emitting messages.
///
/// Conformers can set and use the ``OpenTokSignalChannel`` to send signals during runtime.
/// The channel is usually assigned when the call connects and cleared on disconnect.
///
/// - SeeAlso: ``OpenTokSignalChannel``
public protocol OpenTokSignalEmitter: AnyObject {
    /// The channel used to emit signals; may be `nil` when not connected.
    var channel: OpenTokSignalChannel? { get set }
}

/// Call-based lifecycle for OpenTok plugins.
///
/// Plugins implementing this protocol receive lifecycle callbacks when a call starts/ends.
/// Use these to initialize resources, attach observers, and tear down cleanly.
///
/// ## Lifecycle
/// - ``callDidStart(_:)``: Called after successfully connecting; includes contextual user info.
/// - ``callDidEnd()``: Called during disconnect to allow cleanup.
///
/// - SeeAlso: ``OpenTokPluginCallHolder``, ``OpenTokPluginID``, ``OpenTokPlugin``
public protocol OpenTokPluginCallLifeCycle {
    /// Called when the call starts and the session is connected.
    ///
    /// - Parameter userInfo: Contextual information such as username, room name, and call ID.
    /// - Throws: An error if initialization fails.
    func callDidStart(_ userInfo: [String: Any]) async throws

    /// Called when the call ends and the session is disconnecting.
    ///
    /// - Throws: An error if cleanup fails.
    func callDidEnd() async throws
}

/// Holds a reference to the current call façade for plugin operations.
///
/// The call reference is assigned when connecting and cleared on disconnect
/// so plugins can access publishers, perform actions, or emit signals.
///
/// - SeeAlso: ``OpenTokPluginCallLifeCycle``
public protocol OpenTokPluginCallHolder: AnyObject {
    /// The active call façade, or `nil` when disconnected.
    var call: VERACore.CallFacade? { get set }
}

/// Identifies a plugin with a stable string identifier.
///
/// Use to log lifecycle events, diagnostics, and to manage plugin collections.
public protocol OpenTokPluginID {
    /// A unique identifier for the plugin (e.g., `"chat"`, `"callkit"`).
    var pluginIdentifier: String { get }
}

/// A composite plugin type combining lifecycle and identification.
///
/// Conforming types must provide both lifecycle hooks and a stable identifier.
/// This typealias is used to declare plugin collections in the call façade.
///
/// - SeeAlso: ``OpenTokPluginCallLifeCycle``, ``OpenTokPluginID``
public typealias OpenTokPlugin = OpenTokPluginCallLifeCycle & OpenTokPluginID
