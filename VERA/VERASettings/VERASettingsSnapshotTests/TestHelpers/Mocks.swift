//
//  Created by Vonage on 05/03/2026.
//

import Combine
import VERADomain
import VERASettings

final actor MockStatsSettingsRepository: PublisherSettingsRepository {

    private nonisolated let subject: CurrentValueSubject<PublisherSettingsPreferences, Never>

    nonisolated(unsafe) private(set) var lastSavedPreferences: PublisherSettingsPreferences?

    nonisolated var preferencesPublisher: AnyPublisher<PublisherSettingsPreferences, Never> {
        subject.eraseToAnyPublisher()
    }

    init(initialPreferences: PublisherSettingsPreferences = .default) {
        self.subject = CurrentValueSubject(initialPreferences)
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

    private nonisolated let subject: CurrentValueSubject<NetworkMediaStats, Never>

    nonisolated var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.eraseToAnyPublisher()
    }

    init(initialStats: NetworkMediaStats = .empty) {
        self.subject = CurrentValueSubject(initialStats)
    }

    func updateStats(_ stats: NetworkMediaStats) async {
        subject.send(stats)
    }
}

final actor MockStatsOverlayDataSource: StatsDataSource {

    private nonisolated let subject = CurrentValueSubject<NetworkMediaStats, Never>(.empty)

    nonisolated var statsPublisher: AnyPublisher<NetworkMediaStats, Never> {
        subject.eraseToAnyPublisher()
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
