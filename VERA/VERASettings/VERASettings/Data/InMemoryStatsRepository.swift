//
//  Created by Vonage on 27/02/2026.
//

import Combine
import Foundation
import VERADomain

/// Thread-safe in-memory store for network statistics.
///
/// Implements both ``StatsWriter`` (write path, used by the plugin) and
/// ``StatsDataSource`` (read path, used by view models).
///
/// Uses a `CurrentValueSubject` so new subscribers immediately receive
/// the most recent snapshot.
///
/// - SeeAlso: ``StatsWriter``, ``StatsDataSource``
public actor InMemoryStatsRepository: StatsRepository {

    // MARK: - Private

    /// Owns the subject behind a narrowly audited Combine synchronization boundary.
    private nonisolated let relay = StatsPublisherRelay()

    // MARK: - Init

    /// Creates a new in-memory stats repository.
    public init() {}

    // MARK: - StatsDataSource

    /// A publisher that emits network statistics updates.
    ///
    /// New subscribers immediately receive the most recent stats snapshot on the subscribing context.
    /// Updates and clear send synchronously from this actor; delivery is not guaranteed to use the main thread.
    /// UI observers must select their scheduler, for example with `receive(on:)`.
    public nonisolated var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        relay.publisher
    }

    // MARK: - StatsWriter

    /// Updates the stored statistics and notifies all observers.
    ///
    /// - Parameter stats: The new network media statistics.
    public func updateStats(_ stats: NetworkMediaStats) async {
        relay.send(stats)
    }

    /// Clears all statistics and resets to empty values.
    public func clearStats() async {
        relay.send(.empty)
    }
}
