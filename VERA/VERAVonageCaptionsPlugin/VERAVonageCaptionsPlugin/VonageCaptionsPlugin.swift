//
//  Created by Vonage on 13/10/25.
//

import Combine
import Foundation
import VERACaptions
import VERADomain
import VERAVonage

/// Monitors and manages archiving status for an active Vonage call.
///
/// This plugin listens to archiving signals from the Vonage session and updates
/// the archiving status data source, allowing the application to react to when
/// call recording starts or stops.
///
/// ## Responsibilities
/// - Receives archiving signals from Vonage session
/// - Updates `ArchivingStatusDataSource` with current archiving state
/// - Resets archiving status when the call ends
///
/// - Important: The plugin automatically handles archiving signals of type "archiving"
///   with data values "start" or "stop".
/// - SeeAlso: ``VonagePlugin``, ``VonagePluginCallLifeCycle``,  ``VonageSignalHandler``
public final class VonageCaptionsPlugin: VonagePlugin, VonageSignalHandler, VonagePluginCallHolder {
    private var cancellables = Set<AnyCancellable>()

    /// Supported signal types for this plugin.
    public enum SignalType: String {
        /// Archiving status signals routed via Vonage signaling.
        case archiving
    }

    /// The active call façade reference, used to perform actions
    /// such as `disconnect()`, `setOnHold(_:)`, and `muteLocalMedia(_:)`.
    public weak var call: (any CallFacade)?

    private let captionsStatusDataSource: CaptionsStatusDataSource

    /// A stable identifier for this plugin instance.
    ///
    /// Defaults to the type name (e.g., `"VonageArchivingPlugin"`).
    public var pluginIdentifier: String { String(describing: type(of: self)) }

    /// Creates a new archiving plugin instance.
    ///
    /// - Parameter archivingStatusDataSource: The data source that will be updated with archiving status changes.
    public init(captionsStatusDataSource: CaptionsStatusDataSource) {
        self.captionsStatusDataSource = captionsStatusDataSource
    }

    /// Lifecycle callback invoked when the call starts and the session is connected.
    ///
    /// Currently, this plugin does not require any initialization when the call starts.
    /// Archiving status will be updated via signal handlers during the call lifecycle.
    ///
    /// - Parameters:
    ///   - userInfo: A dictionary with contextual info (not currently used by this plugin).
    public func callDidStart(_ userInfo: [String: Any]) async throws {
        captionsStatusDataSource.captionsState.sink { [weak self] state in
            self?.proccessNewState(state)
        }
        .store(in: &cancellables)
    }

    private func proccessNewState(_ state: CaptionsState) {
        Task {
            switch state {
            case .enabled(let captionsID): await call?.enableCaptions()
            case .disabled: await call?.disableCaptions()
            }
        }
    }

    /// Lifecycle callback invoked when the call ends and the session is disconnecting.
    ///
    /// Resets the archiving status data source to clear any active archiving state.
    public func callDidEnd() async throws {
        captionsStatusDataSource.reset()
        cancellables.removeAll()
    }

    public func handleSignal(_ signal: VERAVonage.VonageSignal) {
    }
}
