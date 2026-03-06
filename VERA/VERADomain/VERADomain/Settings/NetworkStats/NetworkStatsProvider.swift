//
//  Created by Vonage on 22/2/26.
//

import Combine
import Foundation

/// Provides real-time network statistics for the current call session.
///
/// Conformers collect audio and video metrics for both send (publisher) and
/// receive (subscriber) directions and expose them as a reactive Combine publisher.
///
/// The stats collection can be toggled at runtime with ``enableNetworkStats()``
/// and ``disableNetworkStats()``.
///
/// - SeeAlso: ``NetworkMediaStats``, ``CallFacade``
public protocol NetworkStatsProvider: AnyObject {
    /// A publisher that emits aggregated network statistics, never fails.
    ///
    /// Emits ``NetworkMediaStats/empty`` when stats collection is disabled or
    /// no data is available yet.
    var networkStatsPublisher: AnyPublisher<NetworkMediaStats, Never> { get }

    /// Starts collecting network statistics from the SDK.
    ///
    /// Sets up the publisher and subscriber `networkStatsDelegate` so that
    /// periodic updates flow through ``networkStatsPublisher``.
    func enableNetworkStats()

    /// Stops collecting network statistics and clears the current data.
    ///
    /// Removes the SDK delegates and resets ``networkStatsPublisher`` to
    /// ``NetworkMediaStats/empty``.
    func disableNetworkStats()
}
