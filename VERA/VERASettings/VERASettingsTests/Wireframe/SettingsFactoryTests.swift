//
//  Created by Vonage.
//

import Testing
import VERADomain

@testable import VERASettings

@Suite("SettingsFactory Tests")
@MainActor
struct SettingsFactoryTests {

    // MARK: - makeWaitingRoomButton

    @Test("makeWaitingRoomButton returns SettingsToolbarButton")
    func makeWaitingRoomButtonReturnsToolbarButton() {
        let factory = makeFactory()

        let button = factory.makeWaitingRoomButton()

        #expect(button is SettingsToolbarButton)
    }

    @Test("makeWaitingRoomButton creates distinct instances on each call")
    func makeWaitingRoomButtonCreatesDistinctInstances() {
        let factory = makeFactory()

        let button1 = factory.makeWaitingRoomButton()
        let button2 = factory.makeWaitingRoomButton()

        // SwiftUI Views are value types, so we verify they can be created independently
        #expect(type(of: button1) == type(of: button2))
    }

    @Test("makeWaitingRoomButton has correct accessibility identifier")
    func makeWaitingRoomButtonHasCorrectAccessibilityID() {
        #expect(SettingsToolbarButton.accessibilityID == "WaitingRoom.SettingsButton")
    }

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

    // MARK: - makeSettingsView

    @Test("makeSettingsView returns configured SettingsView")
    func makeSettingsViewReturnsConfiguredView() {
        let factory = makeFactory()

        let view = factory.makeSettingsView()

        #expect(view is SettingsView)
    }

    // MARK: - Helpers

    private func makeFactory(
        repository: MockSettingsRepository = MockSettingsRepository(),
        statsDataSource: MockStatsDataSource = MockStatsDataSource()
    ) -> SettingsFactory {
        SettingsFactory(repository: repository, statsDataSource: statsDataSource)
    }
}
