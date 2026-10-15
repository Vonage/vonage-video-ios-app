//
//  Created by Vonage on 13/10/25.
//

import Foundation
import VERAArchiving
import VERADomain
import VERAVonage

/// Monitors and manages archiving status for an active Vonage call.
///
/// This plugin listens to archiving signals from the Vonage session and updates
/// the archiving status data sources, allowing the application to react to when
/// call recording or post-call transcription starts or stops.
///
/// ## Responsibilities
/// - Receives archiving signals from Vonage session
/// - Updates the recording or transcription `ArchivingStatusDataSource` based on the archive kind
/// - Resets both statuses when the call ends
///
/// - Important: The plugin automatically handles archiving signals of type "archiving"
///   with data values "start" or "stop". Signals without a kind are treated as recordings.
/// - SeeAlso: ``VonagePlugin``, ``VonagePluginCallLifeCycle``,  ``VonageSignalHandler``
public final class VonageArchivingPlugin: VonagePlugin, VonageSignalHandler {

    /// Supported signal types for this plugin.
    public enum SignalType: String {
        /// Archiving status signals routed via Vonage signaling.
        case archiving
    }

    private let archivingStatusDataSource: ArchivingStatusDataSource
    private let transcriptionStatusDataSource: ArchivingStatusDataSource

    /// A stable identifier for this plugin instance.
    ///
    /// Defaults to the type name (e.g., `"VonageArchivingPlugin"`).
    public var pluginIdentifier: String { String(describing: type(of: self)) }

    /// Creates a new archiving plugin instance.
    ///
    /// - Parameters:
    ///   - archivingStatusDataSource: The data source updated with recording status changes.
    ///   - transcriptionStatusDataSource: The data source updated with post-call transcription status changes.
    public init(
        archivingStatusDataSource: ArchivingStatusDataSource,
        transcriptionStatusDataSource: ArchivingStatusDataSource
    ) {
        self.archivingStatusDataSource = archivingStatusDataSource
        self.transcriptionStatusDataSource = transcriptionStatusDataSource
    }

    /// Lifecycle callback invoked when the call starts and the session is connected.
    ///
    /// Currently, this plugin does not require any initialization when the call starts.
    /// Archiving status will be updated via signal handlers during the call lifecycle.
    ///
    /// - Parameters:
    ///   - userInfo: A dictionary with contextual info (not currently used by this plugin).
    public func callDidStart(_ userInfo: [String: Any]) async throws {
    }

    /// Lifecycle callback invoked when the call ends and the session is disconnecting.
    ///
    /// Resets the archiving status data sources to clear any active archiving state.
    public func callDidEnd() async throws {
        archivingStatusDataSource.reset()
        transcriptionStatusDataSource.reset()
    }

    public func handleSignal(_ signal: VERAVonage.VonageSignal) {
        guard signal.type == SignalType.archiving.rawValue,
            let data = signal.data
        else { return }

        guard let payload = try? decodeArchivingPayload(from: data) else {
            return
        }

        let statusDataSource = statusDataSource(for: ArchiveKind(archiveName: payload.kind))

        switch payload.action {
        case "start":
            if let archivingID = payload.archivingID {
                statusDataSource.set(archivingState: .archiving(archivingID))
            }
        case "stop":
            statusDataSource.set(archivingState: .idle)
        default:
            break
        }
    }

    private func statusDataSource(for kind: ArchiveKind) -> ArchivingStatusDataSource {
        switch kind {
        case .recording: archivingStatusDataSource
        case .transcription: transcriptionStatusDataSource
        }
    }

    private func decodeArchivingPayload(
        from jsonString: String
    ) throws -> ArchivingPayload {
        guard let data = jsonString.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid UTF8"))
        }
        return try JSONDecoder().decode(ArchivingPayload.self, from: data)
    }

    private struct ArchivingPayload: Decodable {
        let action: String
        let archivingID: String?
        let kind: String?
    }
}
