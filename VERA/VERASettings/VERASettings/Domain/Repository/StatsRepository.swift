//
//  Created by Vonage on 04/03/2026.
//

import Combine
import Foundation
import VERADomain

/// Read-only interface for observing network statistics from the settings module.
///
/// View models subscribe to ``statsPublisher`` to display real-time metrics
/// in the Statistics section and the stats overlay.
///
/// - SeeAlso: ``StatsWriter``, ``InMemoryStatsRepository``
public protocol StatsDataSource: Sendable {
    /// A publisher that emits the latest ``NetworkMediaStats`` snapshot, never fails.
    ///
    /// Emits ``NetworkMediaStats/empty`` when no stats are available.
    var statsPublisher: AnyPublisher<NetworkMediaStats, Never> { get }
}

/// Write-only interface for pushing network statistics into the settings module.
///
/// The ``VonageSettingsPlugin`` writes stats through this protocol every time
/// the SDK's `networkStatsDelegate` delivers an update. Downstream consumers
/// read the same data through ``StatsDataSource``.
///
/// - SeeAlso: ``StatsDataSource``, ``InMemoryStatsRepository``
public protocol StatsWriter: Sendable {
    /// Replaces the current stats snapshot with the given value.
    ///
    /// - Parameter stats: The latest aggregated network media statistics.
    func updateStats(_ stats: NetworkMediaStats) async

    /// Clears all stored stats, resetting to ``NetworkMediaStats/empty``.
    func clearStats() async
}

public typealias StatsRepository = StatsDataSource & StatsWriter
