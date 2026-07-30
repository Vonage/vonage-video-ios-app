//
//  Created by Vonage on 21/05/2026.
//

import Combine

@testable import VERASettings

final actor MockSDKLoggingRepository: SDKLoggingRepository {
    private nonisolated let subject: CurrentValueSubject<SDKLoggingPreferences, Never>

    nonisolated(unsafe) private(set) var saveCallCount = 0
    nonisolated(unsafe) private(set) var resetCallCount = 0
    nonisolated(unsafe) private(set) var lastSavedPreferences: SDKLoggingPreferences?

    nonisolated var preferencesPublisher: AnyPublisher<SDKLoggingPreferences, Never> {
        subject.eraseToAnyPublisher()
    }

    init(initialPreferences: SDKLoggingPreferences = .default) {
        self.subject = CurrentValueSubject(initialPreferences)
    }

    func getPreferences() async -> SDKLoggingPreferences {
        subject.value
    }

    func save(_ preferences: SDKLoggingPreferences) async {
        saveCallCount += 1
        lastSavedPreferences = preferences
        subject.send(preferences)
    }

    func reset() async {
        resetCallCount += 1
        subject.send(.default)
    }

    /// Helper method for tests to update preferences with a closure.
    func updatePreferences(_ update: (inout SDKLoggingPreferences) -> Void) async {
        var preferences = subject.value
        update(&preferences)
        await save(preferences)
    }

    nonisolated func loadPreferencesSync() -> VERASettings.SDKLoggingPreferences {
        subject.value
    }

    nonisolated func savePreferencesSync(_ preferences: VERASettings.SDKLoggingPreferences) {
        saveCallCount += 1
        lastSavedPreferences = preferences
        subject.send(preferences)
    }

}
