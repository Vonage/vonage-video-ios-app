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
            statsDataSource: MockStatsDataSource(),
            speakerTestService: MockSpeakerTestService()
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
        SettingsFactory(repository: repository, statsDataSource: statsDataSource, speakerTestService: MockSpeakerTestService())
    }
}
