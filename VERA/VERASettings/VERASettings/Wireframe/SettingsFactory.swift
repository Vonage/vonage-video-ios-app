//
//  Created by Vonage on 25/2/26.
//

import Foundation

/// Constants used by the settings factory for configuring view models.
private enum SettingsConstants {
    /// Time interval between stats overlay UI updates in seconds.
    /// Set to 0.5 seconds to balance readability with freshness of data.
    static let statsInterval: TimeInterval = 0.5
}

/// Creates VERASettings views and view models.
///
/// Holds a shared ``PublisherSettingsRepository`` and ``StatsDataSource``
/// so that every settings screen, stats overlay, and statistics section
/// observe the same sources of truth.
///
/// This factory ensures consistent dependency injection across the settings module,
/// providing different configurations for waiting room vs. meeting room contexts.
public final class SettingsFactory {

    /// Shared repository for reading and writing publisher settings.
    private let repository: PublisherSettingsRepository

    /// Shared data source for real-time network statistics.
    private let statsDataSource: StatsDataSource

    /// Creates a new settings factory.
    ///
    /// - Parameters:
    ///   - repository: Repository for persisting and observing publisher settings.
    ///   - statsDataSource: Source of real-time network statistics.
    public init(
        repository: PublisherSettingsRepository,
        statsDataSource: StatsDataSource
    ) {
        self.repository = repository
        self.statsDataSource = statsDataSource
    }

    // MARK: - Settings View

    /// Creates a ``SettingsView`` backed by fresh view models.
    ///
    /// This method is suitable for the waiting room where live stats are not needed.
    /// For the meeting room with live statistics, use ``makeMeetingRoomSettingsView()``.
    ///
    /// - Returns: A configured settings view.
    @MainActor
    public func makeSettingsView() -> SettingsView {
        let viewModel = SettingsViewModel(repository: repository)
        return SettingsView(viewModel: viewModel)
    }

    // MARK: - Waiting Room Button

    /// Creates the circular gear button for the waiting room.
    ///
    /// Provides a closure that creates a basic ``SettingsView`` when tapped.
    /// Falls back to a fresh repository if the factory is deallocated.
    ///
    /// - Returns: A configured waiting room settings button.
    @MainActor
    public func makeWaitingRoomButton() -> SettingsWaitingRoomButton {
        SettingsWaitingRoomButton(makeSettingsView: { [weak self] in
            guard let self else {
                let fallbackRepo = UserDefaultsSettingsRepository()
                return SettingsView(
                    viewModel: SettingsViewModel(repository: fallbackRepo)
                )
            }
            return self.makeSettingsView()
        })
    }

    // MARK: - Meeting Room Button

    /// Creates a ``SettingsView`` with real-time statistics for the meeting room.
    ///
    /// Unlike ``makeSettingsView()`` (used for the waiting room), this version
    /// injects a ``StatisticsViewModel`` so that the Stats section displays
    /// live audio/video network metrics.
    @MainActor
    public func makeMeetingRoomSettingsView() -> SettingsView {
        let viewModel = SettingsViewModel(repository: repository)
        let statisticsViewModel = StatisticsViewModel(
            statsDataSource: statsDataSource,
            settingsRepository: repository
        )
        return .init(
            viewModel: viewModel,
            statisticsViewModel: statisticsViewModel
        )
    }

    /// Creates the gear button for the meeting room bottom bar.
    ///
    /// - Parameter onShowSettings: Closure fired when the button is tapped.
    ///   The caller is responsible for presenting the settings sheet.
    @MainActor
    public func makeMeetingRoomButton(onShowSettings: @escaping () -> Void) -> SettingsMeetingRoomButton {
        .init(onShowSettings: onShowSettings)
    }

    // MARK: - Stats Overlay

    /// Creates a ``StatsOverlayViewModel`` that observes the same repository and stats data source.
    ///
    /// The view model is configured with a throttling interval from ``SettingsConstants/statsInterval``
    /// to prevent the overlay text from updating too rapidly for users to read.
    ///
    /// - Returns: A configured stats overlay view model.
    @MainActor
    public func makeStatsOverlayViewModel() -> StatsOverlayViewModel {
        .init(
            settingsRepository: repository,
            statsDataSource: statsDataSource,
            statsUpdateInterval: SettingsConstants.statsInterval
        )
    }

    /// Creates a ``StatsOverlayView`` backed by the given view model.
    ///
    /// - Parameter viewModel: The view model driving the overlay's state and text.
    /// - Returns: A configured stats overlay view.
    @MainActor
    public func makeStatsOverlayView(viewModel: StatsOverlayViewModel) -> StatsOverlayView {
        .init(viewModel: viewModel)
    }
}
