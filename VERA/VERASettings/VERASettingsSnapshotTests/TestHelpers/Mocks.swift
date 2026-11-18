//
//  Created by Vonage on 05/03/2026.
//

import Combine
import VERADomain
import VERASettings

final actor MockStatsSettingsRepository: PublisherSettingsRepository {

    private nonisolated let subject: CurrentValueRelay<PublisherSettingsPreferences, Never>

    private(set) var lastSavedPreferences: PublisherSettingsPreferences?

    nonisolated var preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never> {
        subject.publisher
    }

    init(initialPreferences: PublisherSettingsPreferences = .default) {
        self.subject = CurrentValueRelay(initialPreferences)
    }

    func getPreferences() async -> PublisherSettingsPreferences {
        subject.value
    }

    func save(_ preferences: PublisherSettingsPreferences) async {
        lastSavedPreferences = preferences
        subject.send(preferences)
    }

    func reset() async {
        subject.send(.default)
    }
}

final actor MockStatsDataSource: StatsDataSource {

    private nonisolated let subject: CurrentValueRelay<NetworkMediaStats, Never>

    nonisolated var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.publisher
    }

    init(initialStats: NetworkMediaStats = .empty) {
        self.subject = CurrentValueRelay(initialStats)
    }

    func updateStats(_ stats: NetworkMediaStats) async {
        subject.send(stats)
    }
}

final actor MockStatsOverlayDataSource: StatsDataSource {

    private nonisolated let subject = CurrentValueRelay<NetworkMediaStats, Never>(.empty)

    nonisolated var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.publisher
    }

    func updateStats(_ stats: NetworkMediaStats) async {
        subject.send(stats)
    }

    func updateStats(_ stats: NetworkMediaStats) {
        subject.send(stats)
    }
}

// 0.01 seconds delay
public func delay(nanoseconds duration: UInt64 = 10_000_000) async {
    try? await Task.sleep(nanoseconds: duration)
}
