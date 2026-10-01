//
//  Created by Vonage on 27/02/2026.
//

import Combine
import Foundation
import Observation
import VERADomain

/// View model that observes real-time network statistics for the Statistics section.
///
/// Subscribes to ``StatsDataSource/statsPublisher`` and formats the latest
/// ``NetworkMediaStats`` into display-ready strings for the statistics table.
@Observable
public final class StatisticsViewModel {

    // MARK: - Observable state

    /// The current network media statistics.
    public var stats: NetworkMediaStats = .empty

    /// Whether sender statistics are currently enabled.
    public var isStatsEnabled: Bool = false

    /// Whether the publisher DisclosureGroup is expanded.
    public var isPublisherExpanded: Bool = false

    /// Set of subscriber connection IDs whose DisclosureGroups are expanded.
    public var expandedSubscribers: Set<String> = []

    // MARK: - Dependencies

    /// Data source providing real-time network statistics.
    @ObservationIgnored
    private let statsDataSource: StatsDataSource

    /// Repository providing settings preferences.
    @ObservationIgnored
    private let settingsRepository: PublisherSettingsRepository

    /// Tracks whether the view model has been initialized.
    @ObservationIgnored
    private var isInitialized: Bool = false

    /// Retains the Combine subscriptions feeding the observable state.
    @ObservationIgnored
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    /// Creates a new statistics view model.
    ///
    /// - Parameters:
    ///   - statsDataSource: Provides the real-time stats stream.
    ///   - settingsRepository: Used to observe `senderStatsEnabled`.
    public init(
        statsDataSource: StatsDataSource,
        settingsRepository: PublisherSettingsRepository
    ) {
        self.statsDataSource = statsDataSource
        self.settingsRepository = settingsRepository
    }

    // MARK: - Public

    /// Sets up the observers for stats and settings changes.
    /// Should be called once when the view appears. Subsequent calls are ignored.
    public func setup() {
        guard !isInitialized else { return }
        isInitialized = true

        settingsRepository.preferencesPublisher
            .map(\.senderStatsEnabled)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.isStatsEnabled = isEnabled
            }
            .store(in: &cancellables)

        statsDataSource.statsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.stats = stats
            }
            .store(in: &cancellables)
    }

    // MARK: - Formatting

    /// An inert instance used as a placeholder when real-time stats are not needed
    /// (e.g. the waiting room settings view).
    static let placeholder = StatisticsViewModel(
        statsDataSource: InMemoryStatsRepository(),
        settingsRepository: UserDefaultsSettingsRepository()
    )
}
