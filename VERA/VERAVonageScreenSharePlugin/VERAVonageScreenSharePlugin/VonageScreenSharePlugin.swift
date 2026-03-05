//
//  Created by Vonage on 26/2/26.
//

import Foundation
import VERAScreenShare
import VERAVonage

/// Darwin notification name used to signal the broadcast extension to stop.
private let stopBroadcastNotificationName = "com.vonage.VERA.stopBroadcast" as CFString

/// Vonage plugin that bridges an active call session to the Broadcast Upload Extension.
///
/// When a call starts, this plugin writes the Vonage session credentials
/// (`applicationId`, `sessionId`, `token`) into the shared App Group so the
/// `BroadcastExtension` target can read them and connect its own `OTSession`.
///
/// When the call ends, the credentials are cleared from the shared store.
///
/// ## Usage
/// Register this plugin with `VonagePluginRegistry` before the call connects:
/// ```swift
/// registry.registerPlugin(plugin: VonageScreenSharePlugin(credentialsRepository: repo))
/// ```
///
/// - SeeAlso: ``VonagePlugin``, ``ScreenShareCredentialsRepository``, ``AppGroupScreenShareCredentialsRepository``
public final class VonageScreenSharePlugin: VonagePlugin {

    private let credentialsRepository: ScreenShareCredentialsRepository

    /// A stable identifier for this plugin instance.
    public var pluginIdentifier: String { String(describing: type(of: self)) }

    /// Creates a new screen-share plugin.
    ///
    /// - Parameter credentialsRepository: The repository used to persist session credentials.
    ///   Defaults to the App Group-backed implementation.
    public init(credentialsRepository: ScreenShareCredentialsRepository = AppGroupScreenShareCredentialsRepository()) {
        self.credentialsRepository = credentialsRepository
    }

    /// Stores the active session credentials in the shared App Group so the
    /// Broadcast Upload Extension can connect to the same Vonage session.
    ///
    /// - Parameter userInfo: Must contain `VonageCallParams.applicationId`,
    ///   `VonageCallParams.sessionId`, and `VonageCallParams.token` keys.
    public func callDidStart(_ userInfo: [String: Any]) async throws {
        guard
            let applicationId = userInfo[VonageCallParams.applicationId.rawValue] as? String,
            let sessionId = userInfo[VonageCallParams.sessionId.rawValue] as? String,
            let token = userInfo[VonageCallParams.token.rawValue] as? String
        else { return }

        let credentials = ScreenShareCredentials(
            applicationId: applicationId,
            sessionId: sessionId,
            token: token)
        credentialsRepository.save(credentials)
    }

    /// Clears the stored credentials from the shared App Group and signals
    /// the broadcast extension to stop via a Darwin notification.
    public func callDidEnd() async throws {
        credentialsRepository.clear()

        postStopBroadcastNotification()
    }

    /// Post Darwin notification to signal the broadcast extension to stop
    private func postStopBroadcastNotification() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(stopBroadcastNotificationName),
            nil,
            nil,
            true
        )
    }
}
