//
//  Created by Vonage on 06/03/2026.
//

import Combine
import VERADomain
import VERASettings

final actor MockSettingsRepository: PublisherSettingsRepository {

    private nonisolated let subject: CurrentValueRelay<PublisherSettingsPreferences, Never>

    private(set) var saveCallCount = 0
    private(set) var resetCallCount = 0
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
        saveCallCount += 1
        lastSavedPreferences = preferences
        subject.send(preferences)
    }

    func reset() async {
        resetCallCount += 1
        subject.send(.default)
    }

    /// Helper method for tests to update preferences with a closure
    func updatePreferences(_ update: @Sendable (inout PublisherSettingsPreferences) -> Void) async {
        var preferences = subject.value
        update(&preferences)
        await save(preferences)
    }
}
