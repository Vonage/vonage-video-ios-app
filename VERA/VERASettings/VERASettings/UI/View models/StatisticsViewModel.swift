//
//  Created by Vonage on 27/02/2026.
//

import Combine
import Foundation
import VERADomain

/// View model that observes real-time network statistics for the Statistics section.
///
/// Subscribes to ``StatsDataSource/statsPublisher`` and formats the latest
/// ``NetworkMediaStats`` into display-ready strings for the statistics table.
public final class StatisticsViewModel: ObservableObject {

    // MARK: - Published state

    /// The current network media statistics.
    @Published public var stats: NetworkMediaStats = .empty

    /// Whether sender statistics are currently enabled.
    @Published public var isStatsEnabled: Bool = false

    /// A formatted string of the estimated bandwidth, or `nil` if unavailable.
    public var estimatedBandwidthFormatted: String? {
        SettingsFormatter.formatBandwidth(stats.receivedAudio?.estimatedBandwidth)
    }

    // MARK: - Dependencies

    /// Data source providing real-time network statistics.
    private let statsDataSource: StatsDataSource

    /// Repository providing settings preferences.
    private let settingsRepository: PublisherSettingsRepository

    /// Tracks whether the view model has been initialized.
    private var isInialized: Bool = false

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
        guard !isInialized else { return }
        isInialized = true

        settingsRepository.preferencesPublisher
            .map(\.senderStatsEnabled)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .assign(to: &$isStatsEnabled)

        statsDataSource.statsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$stats)
    }

    // MARK: - Formatting

    /// An inert instance used as a placeholder when real-time stats are not needed
    /// (e.g. the waiting room settings view).
    static let placeholder = StatisticsViewModel(
        statsDataSource: InMemoryStatsRepository(),
        settingsRepository: UserDefaultsSettingsRepository()
    )
}
