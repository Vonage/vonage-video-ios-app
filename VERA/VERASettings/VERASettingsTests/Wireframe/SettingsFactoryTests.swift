//
//  Created by Vonage.
//

import Testing
import VERADomain

@testable import VERASettings

@Suite("SettingsFactory Tests")
@MainActor
struct SettingsFactoryTests {

    // MARK: - makeMeetingRoomViewModels

    @Test("makeMeetingRoomViewModels returns properly initialized view models")
    func makeMeetingRoomViewModelsReturnsInitializedViewModels() {
        let factory = makeFactory()

        let (viewModel, statisticsViewModel) = factory.makeMeetingRoomViewModels()

        #expect(viewModel.senderStatsEnabled == false)
        #expect(statisticsViewModel.stats == .empty)
        #expect(statisticsViewModel.isStatsEnabled == false)
    }

    @Test("makeMeetingRoomViewModels creates distinct instances on each call")
    func makeMeetingRoomViewModelsCreatesDistinctInstances() {
        let factory = makeFactory()

        let (vm1, statsVM1) = factory.makeMeetingRoomViewModels()
        let (vm2, statsVM2) = factory.makeMeetingRoomViewModels()

        #expect(vm1 !== vm2)
        #expect(statsVM1 !== statsVM2)
    }

    @Test("makeMeetingRoomViewModels with stats enabled repository")
    func makeMeetingRoomViewModelsWithStatsEnabled() async {
        let repository = MockSettingsRepository(
            initialPreferences: PublisherSettingsPreferences(senderStatsEnabled: true)
        )
        let factory = SettingsFactory(
            repository: repository,
            statsDataSource: MockStatsDataSource()
        )

        let (viewModel, _) = factory.makeMeetingRoomViewModels()
        await viewModel.setup()

        #expect(viewModel.senderStatsEnabled == true)
    }

    // MARK: - Helpers

    private func makeFactory(
        repository: MockSettingsRepository = MockSettingsRepository(),
        statsDataSource: MockStatsDataSource = MockStatsDataSource()
    ) -> SettingsFactory {
        SettingsFactory(repository: repository, statsDataSource: statsDataSource)
    }

    // MARK: - Logging Dependencies

    @Test("Factory initializes with logging dependencies")
    func factoryInitializesWithLoggingDependencies() {
        let repository = MockSettingsRepository()
        let statsDataSource = MockStatsDataSource()
        let loggingRepository = MockSDKLoggingRepository()
        let logURLs = [URL(fileURLWithPath: "/tmp/test.log")]

        let factory = SettingsFactory(
            repository: repository,
            statsDataSource: statsDataSource,
            loggingRepository: loggingRepository,
            loggingPreferencesLoader: { .default },
            logFileURLProvider: { logURLs }
        )

        let (viewModel, _) = factory.makeMeetingRoomViewModels()
        #expect(viewModel.hasLoggingSupport == true)
    }

    @Test("Factory without logging dependencies creates view model without logging support")
    func factoryWithoutLoggingCreatesViewModelWithoutLogging() {
        let factory = makeFactory()

        let (viewModel, _) = factory.makeMeetingRoomViewModels()
        #expect(viewModel.hasLoggingSupport == false)
    }

    @Test("makeMeetingRoomViewModels with logging prefs loader provides initial state")
    func makeMeetingRoomViewModelsWithLoggingPrefsLoader() {
        let loggingRepository = MockSDKLoggingRepository()
        let factory = SettingsFactory(
            repository: MockSettingsRepository(),
            statsDataSource: MockStatsDataSource(),
            loggingRepository: loggingRepository,
            loggingPreferencesLoader: {
                SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .warn)
            }
        )

        let (viewModel, _) = factory.makeMeetingRoomViewModels()
        #expect(viewModel.isLoggingEnabled == true)
        #expect(viewModel.sdkLogLevel == .warn)
    }

    @Test("makeMeetingRoomViewModels with log file provider exposes URLs")
    func makeMeetingRoomViewModelsWithLogFileProvider() {
        let expectedURLs = [URL(fileURLWithPath: "/tmp/sdk.log")]
        let factory = SettingsFactory(
            repository: MockSettingsRepository(),
            statsDataSource: MockStatsDataSource(),
            loggingRepository: MockSDKLoggingRepository(),
            logFileURLProvider: { expectedURLs }
        )

        let (viewModel, _) = factory.makeMeetingRoomViewModels()
        #expect(viewModel.logFileURLs == expectedURLs)
        #expect(viewModel.hasLogFiles == true)
    }

    @Test("makeSettingsView creates view with logging support when configured")
    func makeSettingsViewWithLogging() {
        let factory = SettingsFactory(
            repository: MockSettingsRepository(),
            statsDataSource: MockStatsDataSource(),
            loggingRepository: MockSDKLoggingRepository(),
            loggingPreferencesLoader: {
                SDKLoggingPreferences(isLoggingEnabled: true, logLevel: .error)
            }
        )

        let view = factory.makeSettingsView()
        #expect(view.viewModel.hasLoggingSupport == true)
        #expect(view.viewModel.isLoggingEnabled == true)
        #expect(view.viewModel.sdkLogLevel == .error)
    }

    @Test("makeSettingsView creates view without logging when not configured")
    func makeSettingsViewWithoutLogging() {
        let factory = makeFactory()

        let view = factory.makeSettingsView()
        #expect(view.viewModel.hasLoggingSupport == false)
    }

    @Test("makeMeetingRoomSettingsView creates view with statistics")
    func makeMeetingRoomSettingsViewCreatesView() {
        let factory = SettingsFactory(
            repository: MockSettingsRepository(),
            statsDataSource: MockStatsDataSource(),
            loggingRepository: MockSDKLoggingRepository(),
            loggingPreferencesLoader: { .default }
        )

        let view = factory.makeMeetingRoomSettingsView()
        #expect(view.viewModel.hasLoggingSupport == true)
    }

    @Test("makeMeetingRoomButton creates button with action")
    func makeMeetingRoomButtonCreatesButton() {
        let factory = makeFactory()
        var actionCalled = false

        _ = factory.makeMeetingRoomButton {
            actionCalled = true
        }

        // Button is created successfully — action is not called yet
        #expect(!actionCalled)
    }

    @Test("makeStatsOverlayViewModel creates configured view model")
    func makeStatsOverlayViewModelCreatesViewModel() {
        let factory = makeFactory()

        let viewModel = factory.makeStatsOverlayViewModel()
        #expect(viewModel.isActive == false)
    }
}
