//
//  Created by Vonage on 08/06/2026.
//

public final class FeedbackFactory {

    public init() {
        
    }

    @MainActor
    public func makeFeedbackView() -> FeedbackView {
        let viewModel = FeedbackViewModel()
        return FeedbackView(viewModel: viewModel)
    }

    // MARK: - Waiting Room Button

    /// Creates the circular gear button for the waiting room.
    ///
    /// Provides a closure that creates a basic ``SettingsView`` when tapped.
    /// Falls back to a fresh repository if the factory is deallocated.
    ///
    /// - Returns: A configured waiting room settings button.
//    @MainActor
//    public func makeWaitingRoomButton() -> FeedbackComponentButton {
//        FeedbackComponentButton(onShowFeedbackForm: {
//
//        })
//
//        SettingsWaitingRoomButton(makeSettingsView: { [weak self] in
//            guard let self else {
//                let fallbackRepo = UserDefaultsSettingsRepository()
//                return SettingsView(
//                    viewModel: SettingsViewModel(repository: fallbackRepo)
//                )
//            }
//            return self.makeSettingsView()
//        })
//    }

    // MARK: - Meeting Room Button

    /// Creates a ``SettingsView`` with real-time statistics for the meeting room.
    ///
    /// Unlike ``makeSettingsView()`` (used for the waiting room), this version
    /// injects a ``StatisticsViewModel`` so that the Stats section displays
    /// live audio/video network metrics.
//    @MainActor
//    public func makeMeetingRoomSettingsView() -> SettingsView {
//        let (viewModel, statisticsViewModel) = makeMeetingRoomViewModels()
//        return .init(
//            viewModel: viewModel,
//            statisticsViewModel: statisticsViewModel
//        )
//    }

    /// Creates the view models for the meeting room settings without building the view.
    ///
    /// Used by ``SettingsSheetContent`` to own the view models via `@StateObject`,
    /// ensuring they survive parent re-renders while the sheet is presented.
    ///
    /// - Returns: A tuple of the settings view model and the statistics view model.
//    @MainActor
//    public func makeMeetingRoomViewModels() -> (SettingsViewModel, StatisticsViewModel) {
//        let viewModel = SettingsViewModel(repository: repository)
//        let statisticsViewModel = StatisticsViewModel(
//            statsDataSource: statsDataSource,
//            settingsRepository: repository
//        )
//        return (viewModel, statisticsViewModel)
//    }

    /// Creates the gear button for the meeting room bottom bar.
    ///
    /// - Parameter onShowSettings: Closure fired when the button is tapped.
    ///   The caller is responsible for presenting the settings sheet.
    @MainActor
    public func makeMeetingRoomButton(onShowFeedbackForm: @escaping () -> Void) -> FeedbackComponentButton {
        .init(onShowFeedbackForm: onShowFeedbackForm)
    }

    // MARK: - Stats Overlay

    /// Creates a ``StatsOverlayViewModel`` that observes the same repository and stats data source.
    ///
    /// The view model is configured with a throttling interval from ``SettingsConstants/statsInterval``
    /// to prevent the overlay text from updating too rapidly for users to read.
    ///
    /// - Returns: A configured stats overlay view model.
//    @MainActor
//    public func makeStatsOverlayViewModel() -> StatsOverlayViewModel {
//        .init(
//            settingsRepository: repository,
//            statsDataSource: statsDataSource,
//            statsUpdateInterval: SettingsConstants.statsInterval
//        )
//    }
//
//    /// Creates a ``StatsOverlayView`` backed by the given view model.
//    ///
//    /// - Parameter viewModel: The view model driving the overlay's state and text.
//    /// - Returns: A configured stats overlay view.
//    @MainActor
//    public func makeStatsOverlayView(viewModel: StatsOverlayViewModel) -> StatsOverlayView {
//        .init(viewModel: viewModel)
//    }
}
