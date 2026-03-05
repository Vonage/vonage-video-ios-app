//
//  Created by Vonage on 13/10/25.
//

import CallKit
import Foundation
import OpenTok
import VERADomain
import VERAVonage

/// Integrates CallKit with an active Vonage call.
///
/// This plugin bridges CallKit events (start, connect, hold, mute, end) with the
/// call façade, ensuring system-level telephony UX (lock screen, recent calls, interruptions)
/// stays in sync with media state and session lifecycle.
///
/// ## Responsibilities
/// - Starts and ends calls via `VERACallManager`
/// - Reports connection and configures hold on `ProviderDelegate`
/// - Syncs CallKit events to the call façade (`hold`, `mute`, `end`)
///
/// - Important: Call `setup()` before using the plugin to initialize the CallKit
///   machinery and delegate callbacks.
/// - SeeAlso: ``VonagePlugin``, ``VonagePluginCallLifeCycle``, ``VonagePluginCallHolder``, ``VonageCallParams``
/// - Note: The plugin requires a valid `callID` UUID in `userInfo` to drive CallKit.
///   If parsing fails, it throws ``VonageCallKitPlugin/Error/invalidCallID``.
/// - Warning: CallKit is not supported on the iOS Simulator. When the plugin is
///   active on a Simulator target, `OTPublisher` fails to publish with a connection
///   timeout. Skip `setup()` or guard with `#if !targetEnvironment(simulator)` when
///   running on Simulator.
public final class VonageCallKitPlugin: VonagePlugin, VonagePluginCallHolder {

    /// Errors emitted by the CallKit plugin.
    public enum Error: Swift.Error {
        /// The provided call ID is not a valid UUID string.
        case invalidCallID
    }

    /// The active call façade reference, used to perform actions
    /// such as `disconnect()`, `setOnHold(_:)`, and `muteLocalMedia(_:)`.
    public weak var call: (any CallFacade)?

    /// Manages CallKit interactions for starting/ending calls.
    var callManager: VERACallManager!
    /// Manages the AVAudioSession in Calling Services mode.
    var sessionManager: OTAudioSessionManager!
    /// Handles CallKit provider events and reports state.
    var providerDelegate: ProviderDelegate?
    /// The current CallKit call identifier associated with the session.
    var currentCallID: UUID?

    /// A stable identifier for this plugin instance.
    ///
    /// Defaults to the type name (e.g., `"VonageCallKitPlugin"`).
    public var pluginIdentifier: String { String(describing: type(of: self)) }

    /// Creates a new CallKit plugin instance.
    public init() {}

    /// Lifecycle callback invoked when the call starts and the session is connected.
    ///
    /// Expects `userInfo` to contain:
    /// - ``VonageCallParams/roomName``: The display handle for the call
    /// - ``VonageCallParams/callID``: A UUID string identifying the CallKit call
    ///
    /// If the `callID` is a valid UUID, it:
    /// - Stores the `currentCallID`
    /// - Starts the CallKit call via `VERACallManager`
    /// - Reports connected state and configures hold on `ProviderDelegate`
    ///
    /// - Parameters:
    ///   - userInfo: A dictionary with contextual info (room name and call ID).
    /// - Throws: ``VonageCallKitPlugin/Error/invalidCallID`` if `callID` cannot be parsed.
    /// - SeeAlso: ``VonageCallParams``
    public func callDidStart(_ userInfo: [String: Any]) async throws {
        #if !targetEnvironment(simulator)
            let roomName = userInfo[VonageCallParams.roomName.rawValue] as? String ?? ""
            let callID = userInfo[VonageCallParams.callID.rawValue] as? String ?? ""

            if let callUUID = UUID(uuidString: callID) {
                currentCallID = callUUID
                try await callManager.startCall(handle: roomName, callID: callUUID)
                providerDelegate?.reportConnected(callUUID: callUUID)
                providerDelegate?.setupHold(to: callUUID)
            } else {
                throw Error.invalidCallID
            }
        #endif
    }

    /// Lifecycle callback invoked when the call ends and the session is disconnecting.
    ///
    /// If a `currentCallID` exists, it:
    /// - Clears `currentCallID`
    /// - Ends the CallKit call via `VERACallManager`
    ///
    /// - Throws: An error if `VERACallManager` fails to end the call.
    public func callDidEnd() async throws {
        #if !targetEnvironment(simulator)
            guard let currentCallID = currentCallID else { return }
            self.currentCallID = nil
            try await callManager.end(callID: currentCallID)
        #endif
    }

    /// Initializes CallKit and audio session components and wires provider events.
    ///
    /// Sets up:
    /// - `VERACallManager` to manage CallKit transactions
    /// - `OTAudioSessionManager` in Calling Services mode
    /// - `ProviderDelegate` event handlers to sync with the call façade:
    ///   - `onEndCall`: Ends the call unless the call is currently on hold
    ///   - `onProviderReset`: Ends the call on provider reset
    ///   - `onHold`: Toggles call hold state on the façade
    ///   - `onMute`: Toggles local media mute on the façade
    ///
    /// - Important: Must be called before invoking lifecycle methods or handling events.
    /// - Note: End-call events are ignored while on hold to preserve the paused state.
    public func setup() {
        #if !targetEnvironment(simulator)
            callManager = VERACallManager()
            sessionManager = OTAudioDeviceManager.currentAudioSessionManager()
            sessionManager?.enableCallingServicesMode()
            providerDelegate = ProviderDelegate(sessionManager: sessionManager)
            providerDelegate?.onEndCall = { [weak self] in
                Task { [weak self] in
                    guard let self else { return }
                    if let isOnHold = self.call?.isOnHold, isOnHold {
                        // Ignore end call event
                    } else {
                        self.currentCallID = nil
                        try? await self.call?.disconnect()
                    }
                }
            }
            providerDelegate?.onProviderReset = { [weak self] in
                Task { [weak self] in
                    self?.currentCallID = nil
                    try? await self?.call?.disconnect()
                }
            }
            providerDelegate?.onHold = { [weak self] isOnHold in
                self?.call?.setOnHold(isOnHold)
            }
            providerDelegate?.onMute = { [weak self] isMuted in
                self?.call?.muteLocalMedia(isMuted)
            }
        #endif
    }
}
